package main

import (
	"archive/zip"
	"crypto/sha256"
	"fmt"
	"os"
	"path/filepath"
	"testing"
)

func writeArchive(t *testing.T, files []string) string {
	t.Helper()
	file := filepath.Join(t.TempDir(), "package.zip")
	f, err := os.Create(file)
	if err != nil {
		t.Fatal(err)
	}
	w := zip.NewWriter(f)
	for _, name := range files {
		entry, err := w.Create(name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err = entry.Write([]byte("contents")); err != nil {
			t.Fatal(err)
		}
	}
	if err := w.Close(); err != nil {
		t.Fatal(err)
	}
	if err := f.Close(); err != nil {
		t.Fatal(err)
	}
	return file
}

func TestVerifyAndExtract(t *testing.T) {
	archive := writeArchive(t, []string{"prismlauncher.exe", "platforms/qwindows.dll"})
	data, err := os.ReadFile(archive)
	if err != nil {
		t.Fatal(err)
	}
	if err := verifyArchive(archive, fmt.Sprintf("%x", sha256.Sum256(data))); err != nil {
		t.Fatal(err)
	}
	if err := verifyArchive(archive, fmt.Sprintf("%064x", 1)); err == nil {
		t.Fatal("expected checksum mismatch")
	}
	dir := t.TempDir()
	if err := extract(archive, dir); err != nil {
		t.Fatal(err)
	}
	if data, err := os.ReadFile(filepath.Join(dir, "platforms", "qwindows.dll")); err != nil || string(data) != "contents" {
		t.Fatalf("invalid output: %q (%v)", data, err)
	}
	if err := extract(archive, dir); err == nil {
		t.Fatal("must refuse to overwrite")
	}
}

func TestRejectUnsafeArchive(t *testing.T) {
	for _, names := range [][]string{
		{"../escaped"}, {"C:/a.dll"}, {"x\\y"}, {"dir/../file"}, {"foo/AUX.zip"},
		{"plugins/a.dll", "Plugins/A.dll"}, {"prismlauncher.exe:stream"}, {"name.dll."},
	} {
		t.Run(fmt.Sprint(names), func(t *testing.T) {
			archive := writeArchive(t, names)
			if err := extract(archive, t.TempDir()); err == nil {
				t.Errorf("accepted %v", names)
			}
		})
	}
}
