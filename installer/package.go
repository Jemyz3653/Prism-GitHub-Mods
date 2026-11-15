// SPDX-License-Identifier: GPL-3.0-only
package main

import (
	"archive/zip"
	"crypto/sha256"
	"debug/pe"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
	"path"
	"path/filepath"
	"strings"
)

const archiveName = "Prism-11.1.1-GitHub-Windows-x64.zip"
const maxPackage = 384 * 1024 * 1024

func verifyArchive(file, expected string) error {
	digest, err := hex.DecodeString(expected)
	if err != nil || len(digest) != sha256.Size {
		return errors.New("неверная контрольная сумма SHA-256")
	}
	f, err := os.Open(file)
	if err != nil {
		return err
	}
	defer f.Close()
	hash := sha256.New()
	n, err := io.Copy(hash, io.LimitReader(f, maxPackage+1))
	if err != nil {
		return err
	}
	if n > maxPackage || hex.EncodeToString(hash.Sum(nil)) != strings.ToLower(expected) {
		return errors.New("архив повреждён или не совпадает с SHA-256 релиза")
	}
	return nil
}

func windowsPath(name string) bool {
	if strings.ContainsAny(name, "\\:\x00") || path.IsAbs(name) || path.Clean(name) != name || !filepath.IsLocal(name) {
		return false
	}
	for _, part := range strings.Split(name, "/") {
		if strings.HasSuffix(part, ".") || strings.HasSuffix(part, " ") || strings.ContainsAny(part, "<>\"|?*") {
			return false
		}
		stem, _, _ := strings.Cut(strings.ToUpper(part), ".")
		switch stem {
		case "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
			"LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9":
			return false
		}
	}
	return true
}

func extract(file, dest string) error {
	r, err := zip.OpenReader(file)
	if err != nil {
		return err
	}
	defer r.Close()
	var total uint64
	if len(r.File) > 20000 {
		return errors.New("слишком много файлов в архиве")
	}
	seen := make(map[string]bool)
	for _, entry := range r.File {
		name := strings.TrimSuffix(entry.Name, "/")
		key := strings.ToLower(name)
		if !windowsPath(name) || seen[key] {
			return fmt.Errorf("небезопасный путь в архиве: %s", name)
		}
		seen[key] = true
		if entry.UncompressedSize64 > 1024*1024*1024-total {
			return errors.New("слишком большой архив Prism")
		}
		total += entry.UncompressedSize64
		if entry.Mode().Type() != 0 && !entry.FileInfo().IsDir() {
			return errors.New("архив содержит ссылку или специальный файл")
		}
		target := filepath.Join(dest, filepath.FromSlash(name))
		if entry.FileInfo().IsDir() {
			err = os.MkdirAll(target, 0755)
		} else {
			err = extractFile(entry, target)
		}
		if err != nil {
			return err
		}
	}
	return nil
}

func extractFile(entry *zip.File, target string) error {
	if err := os.MkdirAll(filepath.Dir(target), 0755); err != nil {
		return err
	}
	input, err := entry.Open()
	if err != nil {
		return err
	}
	defer input.Close()
	output, err := os.OpenFile(target, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0644)
	if err != nil {
		return err
	}
	n, copyErr := io.Copy(output, io.LimitReader(input, int64(entry.UncompressedSize64)+1))
	closeErr := output.Close()
	if n != int64(entry.UncompressedSize64) {
		return errors.New("неверный размер файла в ZIP")
	}
	return errors.Join(copyErr, closeErr)
}

func prismExecutable(file string) error {
	if !strings.EqualFold(filepath.Base(file), "prismlauncher.exe") {
		return errors.New("выбери файл prismlauncher.exe")
	}
	exe, err := pe.Open(file)
	if err != nil {
		return fmt.Errorf("не удалось открыть prismlauncher.exe: %w", err)
	}
	defer exe.Close()
	if exe.Machine != pe.IMAGE_FILE_MACHINE_AMD64 || exe.OptionalHeader == nil || exe.Characteristics&0x2000 != 0 {
		return errors.New("для этой сборки нужен Prism Launcher для Windows x64")
	}
	return nil
}
