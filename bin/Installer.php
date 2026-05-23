<?php

namespace JeanPierreGassin\AiContext;

use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use RuntimeException;
use SplFileInfo;

final class Installer
{
    private const MANAGED_BEGIN = '# BEGIN ai-context managed ignores';
    private const MANAGED_END = '# END ai-context managed ignores';

    public static function installFromComposer(mixed $event): void
    {
        $io = self::composerIo($event);
        $stats = self::install(
            sourceRoot: dirname(__DIR__) . DIRECTORY_SEPARATOR . 'src',
            projectRoot: self::projectRoot(),
            io: $io,
        );

        self::write($io, sprintf(
            'ai-context: installed %d file(s), skipped %d file(s), failed %d file(s).',
            $stats->getInstalled(),
            $stats->getSkipped(),
            $stats->getFailed(),
        ));

        if ($stats->getFailed() > 0) {
            throw new RuntimeException('ai-context install failed.');
        }
    }

    private static function install(string $sourceRoot, string $projectRoot, object $io): InstallStats
    {
        $stats = new InstallStats();

        if (!is_dir($sourceRoot)) {
            self::write($io, sprintf('ai-context: source directory not found: %s', $sourceRoot));
            $stats->incrementFailed();

            return $stats;
        }

        $sourceRoot = rtrim($sourceRoot, DIRECTORY_SEPARATOR);
        $projectRoot = rtrim($projectRoot, DIRECTORY_SEPARATOR);

        self::deployFiles($sourceRoot, $projectRoot, $io, $stats);
        self::deployManagedGitignore($sourceRoot, $projectRoot, '.agents', $io, $stats);
        self::deployManagedGitignore($sourceRoot, $projectRoot, '.claude', $io, $stats);

        return $stats;
    }

    private static function projectRoot(): string
    {
        $projectRoot = getcwd();

        if ($projectRoot === false) {
            return dirname(__DIR__);
        }

        return $projectRoot;
    }

    private static function deployFiles(string $sourceRoot, string $projectRoot, object $io, InstallStats $stats): void
    {
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($sourceRoot, RecursiveDirectoryIterator::SKIP_DOTS),
        );

        /** @var SplFileInfo $item */
        foreach ($iterator as $item) {
            if (!$item->isFile()) {
                continue;
            }

            $relativePath = substr($item->getPathname(), strlen($sourceRoot) + 1);
            $targetPath = $projectRoot . DIRECTORY_SEPARATOR . $relativePath;

            if (!self::ensureDirectory(dirname($targetPath), dirname($relativePath), $io, $stats)) {
                continue;
            }

            self::deployFile($item->getPathname(), $targetPath, $relativePath, $io, $stats);
        }
    }

    private static function deployFile(
        string $sourcePath,
        string $targetPath,
        string $relativePath,
        object $io,
        InstallStats $stats,
    ): void {
        if (file_exists($targetPath)) {
            if (self::sameContent($sourcePath, $targetPath)) {
                $stats->incrementSkipped();

                return;
            }

            if (is_dir($targetPath)) {
                self::write($io, sprintf('ai-context: cannot overwrite directory %s', $relativePath));
                $stats->incrementFailed();

                return;
            }

            if (!self::confirmOverwrite($io, $relativePath)) {
                $stats->incrementSkipped();

                return;
            }

            if (!@unlink($targetPath)) {
                self::write($io, sprintf('ai-context: failed to remove existing %s', $relativePath));
                $stats->incrementFailed();

                return;
            }
        }

        if (@copy($sourcePath, $targetPath)) {
            $stats->incrementInstalled();

            return;
        }

        self::write($io, sprintf('ai-context: failed to copy %s', $relativePath));
        $stats->incrementFailed();
    }

    private static function deployManagedGitignore(
        string $sourceRoot,
        string $projectRoot,
        string $agentDirectory,
        object $io,
        InstallStats $stats,
    ): void {
        $entries = self::managedSkillIgnoreEntries($sourceRoot, $agentDirectory);

        if ($entries === []) {
            return;
        }

        $path = $projectRoot . DIRECTORY_SEPARATOR . $agentDirectory . DIRECTORY_SEPARATOR . '.gitignore';

        if (!self::ensureDirectory(dirname($path), $agentDirectory, $io, $stats)) {
            return;
        }

        self::writeManagedBlock($path, $entries, $io, $stats);
    }

    /**
     * @return string[]
     */
    private static function managedSkillIgnoreEntries(string $sourceRoot, string $agentDirectory): array
    {
        $skillsDirectory = $sourceRoot . DIRECTORY_SEPARATOR . $agentDirectory . DIRECTORY_SEPARATOR . 'skills';

        if (!is_dir($skillsDirectory)) {
            return [];
        }

        $items = scandir($skillsDirectory);

        if ($items === false) {
            return [];
        }

        $entries = ['/.gitignore'];

        foreach ($items as $item) {
            if ($item === '.' || $item === '..') {
                continue;
            }

            if (is_dir($skillsDirectory . DIRECTORY_SEPARATOR . $item)) {
                $entries[] = sprintf('/skills/%s/', $item);
            }
        }

        sort($entries);

        return $entries;
    }

    /**
     * @param string[] $entries
     */
    private static function writeManagedBlock(string $path, array $entries, object $io, InstallStats $stats): void
    {
        $content = '';

        if (is_file($path)) {
            $currentContent = file_get_contents($path);

            if ($currentContent === false) {
                self::write($io, sprintf('ai-context: failed to read %s', $path));
                $stats->incrementFailed();

                return;
            }

            $content = $currentContent;
        }

        $updated = self::withManagedBlock($content, self::managedBlock($entries));

        if ($updated !== $content && @file_put_contents($path, $updated) === false) {
            self::write($io, sprintf('ai-context: failed to update %s', $path));
            $stats->incrementFailed();
        }
    }

    /**
     * @param string[] $entries
     */
    private static function managedBlock(array $entries): string
    {
        return implode(PHP_EOL, [
            self::MANAGED_BEGIN,
            ...$entries,
            self::MANAGED_END,
        ]);
    }

    private static function withManagedBlock(string $content, string $block): string
    {
        $start = strpos($content, self::MANAGED_BEGIN);
        $end = strpos($content, self::MANAGED_END);

        if ($start !== false && $end !== false && $end > $start) {
            $end += strlen(self::MANAGED_END);

            return substr($content, 0, $start) . $block . substr($content, $end);
        }

        $updated = rtrim($content);

        if ($updated !== '') {
            $updated .= PHP_EOL . PHP_EOL;
        }

        return $updated . $block . PHP_EOL;
    }

    private static function ensureDirectory(string $path, string $label, object $io, InstallStats $stats): bool
    {
        clearstatcache(true, $path);

        if (is_dir($path)) {
            return true;
        }

        $created = @mkdir($path, 0775, true);

        clearstatcache(true, $path);

        if ($created || is_dir($path)) {
            return true;
        }

        self::write($io, sprintf('ai-context: failed to create directory %s', $label));
        $stats->incrementFailed();

        return false;
    }

    private static function sameContent(string $sourcePath, string $targetPath): bool
    {
        if (!is_file($sourcePath) || !is_file($targetPath)) {
            return false;
        }

        $sourceHash = hash_file('sha256', $sourcePath);
        $targetHash = hash_file('sha256', $targetPath);

        return $sourceHash !== false && $sourceHash === $targetHash;
    }

    private static function confirmOverwrite(object $io, string $path): bool
    {
        return (bool) $io->askConfirmation(sprintf('ai-context: overwrite %s? [y/N] ', $path), false);
    }

    private static function write(object $io, string $message): void
    {
        $io->write($message);
    }

    private static function composerIo(mixed $event): object
    {
        if (!is_object($event) || !method_exists($event, 'getIO')) {
            throw new RuntimeException('ai-context installer must be run as a Composer script.');
        }

        $io = $event->getIO();

        if (!is_object($io) || !method_exists($io, 'askConfirmation') || !method_exists($io, 'write')) {
            throw new RuntimeException('ai-context installer could not access Composer IO.');
        }

        return $io;
    }
}
