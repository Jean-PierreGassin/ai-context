<?php

namespace JeanPierreGassin\AiContext\Support;

use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use SplFileInfo;

class Filesystem
{
    private const DIRECTORY_PERMISSIONS = 0775;

    public function joinPaths(string ...$segments): string
    {
        return implode(
            DIRECTORY_SEPARATOR,
            array_map(
                fn (string $segment): string => rtrim($segment, DIRECTORY_SEPARATOR),
                $segments,
            ),
        );
    }

    /**
     * Lists every file below the given root as a path relative to that
     * root, so callers can mirror the tree elsewhere without knowing
     * where it came from.
     *
     * @return string[]
     */
    public function listRelativeFilePaths(string $root): array
    {
        $foundFiles = iterator_to_array(
            new RecursiveIteratorIterator(
                new RecursiveDirectoryIterator($root, RecursiveDirectoryIterator::SKIP_DOTS),
            ),
            false,
        );

        $rootLength = strlen(rtrim($root, DIRECTORY_SEPARATOR)) + 1;
        $relativePaths = array_map(
            fn (SplFileInfo $foundFile): string => substr($foundFile->getPathname(), $rootLength),
            array_filter($foundFiles, fn (SplFileInfo $foundFile): bool => $foundFile->isFile()),
        );

        sort($relativePaths);

        return $relativePaths;
    }

    /**
     * @return string[]
     */
    public function listDirectoryNames(string $root): array
    {
        if (!$this->isDirectory($root)) {
            return [];
        }

        $foundNames = scandir($root);
        if ($foundNames === false) {
            return [];
        }

        $directoryNames = array_filter(
            $foundNames,
            fn (string $foundName): bool => $foundName !== '.'
                && $foundName !== '..'
                && $this->isDirectory($this->joinPaths($root, $foundName)),
        );

        sort($directoryNames);

        return $directoryNames;
    }

    public function exists(string $path): bool
    {
        return file_exists($path);
    }

    public function isDirectory(string $path): bool
    {
        return is_dir($path);
    }

    public function ensureDirectory(string $path): bool
    {
        clearstatcache(true, $path);
        if ($this->isDirectory($path)) {
            return true;
        }

        $wasCreated = @mkdir($path, self::DIRECTORY_PERMISSIONS, true);
        clearstatcache(true, $path);

        return $wasCreated || $this->isDirectory($path);
    }

    public function hasIdenticalContent(string $sourcePath, string $targetPath): bool
    {
        if (!is_file($sourcePath) || !is_file($targetPath)) {
            return false;
        }

        $sourceHash = hash_file('sha256', $sourcePath);
        $targetHash = hash_file('sha256', $targetPath);

        return $sourceHash !== false && $sourceHash === $targetHash;
    }

    public function copy(string $sourcePath, string $targetPath): bool
    {
        return @copy($sourcePath, $targetPath);
    }

    public function read(string $path): ?string
    {
        $contents = @file_get_contents($path);

        return $contents === false ? null : $contents;
    }

    public function write(string $path, string $contents): bool
    {
        return @file_put_contents($path, $contents) !== false;
    }

    public function delete(string $path): bool
    {
        return @unlink($path);
    }
}
