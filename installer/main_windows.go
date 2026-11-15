// SPDX-License-Identifier: GPL-3.0-only
package main

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

//go:embed setup.ps1
var setupScript []byte

const releaseBase = "https://github.com/Jemyz3653/Prism-GitHub-Mods/releases/download/v0.2.0/"

type InstallRequest struct {
	Original string
	Data     string
}

type Result struct {
	Status string
	Done   bool
	Error  string
	Exe    string
	Data   string
}

func result(dir string, r Result) {
	data, err := json.Marshal(r)
	if err == nil {
		// The UI ignores a partial read and polls for the next complete JSON result.
		_ = os.WriteFile(filepath.Join(dir, "result.json"), data, 0600)
	}
}

func main() {
	if len(os.Args) == 3 && os.Args[1] == "--install" {
		r, err := install(os.Args[2])
		if err != nil {
			r.Error = err.Error()
		}
		r.Done = true
		result(os.Args[2], r)
		return
	}
	if len(os.Args) != 1 {
		return
	}
	if err := launchUI(); err != nil {
		alert(err.Error())
	}
}

func alert(s string) {
	proc := syscall.NewLazyDLL("user32.dll").NewProc("MessageBoxW")
	message, _ := syscall.UTF16PtrFromString(s)
	title, _ := syscall.UTF16PtrFromString("Prism GitHub Mods")
	_, _, _ = proc.Call(0, uintptr(unsafe.Pointer(message)), uintptr(unsafe.Pointer(title)), 0x10)
}

func launchUI() error {
	work, err := os.MkdirTemp("", "PrismGitHubSetup-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(work)
	self, err := os.Executable()
	if err != nil {
		return err
	}
	ps := filepath.Join(os.Getenv("SystemRoot"), "System32", "WindowsPowerShell", "v1.0", "powershell.exe")
	const start = `[Console]::InputEncoding = [Text.Encoding]::UTF8; & ([ScriptBlock]::Create([Console]::In.ReadToEnd()))`
	cmd := exec.Command(ps, "-NoLogo", "-NoProfile", "-STA", "-NonInteractive", "-Command", start)
	cmd.Stdin = bytes.NewReader(setupScript)
	cmd.Env = append(os.Environ(), "PRISM_SETUP_EXE="+self, "PRISM_SETUP_TEMP="+work)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("Не удалось открыть установщик. %s", strings.TrimSpace(string(output)))
	}
	return nil
}

func download(url, dest string, limit int64) error {
	client := &http.Client{
		Timeout: 4 * time.Minute,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			host := req.URL.Hostname()
			if len(via) >= 5 || req.URL.Scheme != "https" || (host != "github.com" && host != "release-assets.githubusercontent.com") {
				return errors.New("недоверенная переадресация загрузки")
			}
			return nil
		},
	}
	response, err := client.Get(url)
	if err != nil {
		return err
	}
	defer response.Body.Close()
	if response.StatusCode != 200 {
		return fmt.Errorf("GitHub ответил HTTP %d", response.StatusCode)
	}
	file, err := os.OpenFile(dest, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
	if err != nil {
		return err
	}
	size, err := io.Copy(file, io.LimitReader(response.Body, limit+1))
	closeErr := file.Close()
	if size > limit {
		return errors.New("размер загрузки превышает предел")
	}
	return errors.Join(err, closeErr)
}

func install(work string) (Result, error) {
	var req InstallRequest
	var installed Result
	body, err := os.ReadFile(filepath.Join(work, "request.json"))
	if err != nil {
		return installed, err
	}
	if err = json.Unmarshal(body, &req); err != nil {
		return installed, err
	}
	if err = prismExecutable(req.Original); err != nil {
		return installed, err
	}
	if info, err := os.Stat(req.Data); err != nil || !info.IsDir() ||
		!filepath.IsAbs(req.Data) {
		return installed, errors.New("выбери существующую папку данных Prism Launcher")
	}
	if _, err := os.Stat(filepath.Join(req.Data, "prismlauncher.cfg")); err != nil {
		return installed, errors.New("в папке данных нет prismlauncher.cfg. Запусти обычный Prism хотя бы один раз или укажи его папку данных")
	}

	// Store releases in separate folders. An interrupted install never touches the selected Prism installation.
	localAppData := os.Getenv("LOCALAPPDATA")
	if !filepath.IsAbs(localAppData) {
		return installed, errors.New("Windows не сообщила папку LocalAppData")
	}
	root := filepath.Join(localAppData, "Detemkur Studios", "Prism GitHub Mods")
	if err := os.MkdirAll(root, 0755); err != nil {
		return installed, err
	}
	staged, err := os.MkdirTemp(root, ".install-")
	if err != nil {
		return installed, err
	}
	defer os.RemoveAll(staged)
	zipFile := filepath.Join(staged, archiveName)
	sumFile := filepath.Join(staged, "sha256")
	result(work, Result{Status: "Скачиваю сборку Prism с GitHub…"})
	if err := download(releaseBase+"Prism-11.1.1-GitHub-Windows-x64.sha256", sumFile, 1024); err != nil {
		return installed, fmt.Errorf("архив релиза v0.2.0 недоступен: %w", err)
	}
	sum, err := os.ReadFile(sumFile)
	if err != nil {
		return installed, err
	}
	digest := strings.TrimSpace(string(sum))
	if err := download(releaseBase+archiveName, zipFile, maxPackage); err != nil {
		return installed, err
	}
	result(work, Result{Status: "Проверяю SHA-256 и распаковываю…"})
	if err := verifyArchive(zipFile, digest); err != nil {
		return installed, err
	}
	prism := filepath.Join(staged, "prism")
	if err := extract(zipFile, prism); err != nil {
		return installed, err
	}
	if err := prismExecutable(filepath.Join(prism, "prismlauncher.exe")); err != nil {
		return installed, err
	}
	if _, err := os.Stat(filepath.Join(prism, "platforms", "qwindows.dll")); err != nil {
		return installed, errors.New("в пакете отсутствует платформенный модуль Qt для Windows")
	}
	dest := filepath.Join(root, "11.1.1-"+digest[:12]+"-"+filepath.Base(staged)[9:])
	if err := os.Rename(prism, dest); err != nil {
		return installed, err
	}
	return Result{Status: "Готово. Открой Моды → Скачать моды → GitHub.", Exe: filepath.Join(dest, "prismlauncher.exe"), Data: req.Data}, nil
}
