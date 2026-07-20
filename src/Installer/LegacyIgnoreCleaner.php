<?php

namespace JeanPierreGassin\AiContext\Installer;

use JeanPierreGassin\AiContext\Data\DeployedFile;
use JeanPierreGassin\AiContext\Enums\DeployOutcome;
use JeanPierreGassin\AiContext\Support\Filesystem;

/**
 * Removes the shared ignore block earlier versions wrote one level
 * above the skills, now that each skill carries its own.
 *
 * Only the delimited block is touched; anything the project added
 * around it is written back untouched, and the file is deleted only
 * when the block was all it ever held.
 */
class LegacyIgnoreCleaner
{
    private const BLOCK_BEGIN = '# BEGIN ai-context managed ignores';
    private const BLOCK_END = '# END ai-context managed ignores';
    private const IGNORE_FILENAME = '.gitignore';

    public function __construct(
        private readonly Filesystem $filesystem,
    ) {
    }

    public function clean(string $projectRoot, string $agentDirectory): ?DeployedFile
    {
        $relativePath = $this->filesystem->joinPaths($agentDirectory, self::IGNORE_FILENAME);
        $targetPath = $this->filesystem->joinPaths($projectRoot, $relativePath);
        $currentIgnores = $this->filesystem->read($targetPath);
        if ($currentIgnores === null || !str_contains($currentIgnores, self::BLOCK_BEGIN)) {
            return null;
        }

        $remainingIgnores = $this->withoutManagedBlock($currentIgnores);
        if (trim($remainingIgnores) === '') {
            return $this->deleteIgnoreFile($targetPath, $relativePath);
        }

        if (!$this->filesystem->write($targetPath, ltrim($remainingIgnores))) {
            return new DeployedFile(
                relativePath: $relativePath,
                outcome: DeployOutcome::Failed,
                reason: 'the superseded ignore block could not be removed',
            );
        }

        return new DeployedFile(relativePath: $relativePath, outcome: DeployOutcome::Removed);
    }

    private function deleteIgnoreFile(string $targetPath, string $relativePath): DeployedFile
    {
        if (!$this->filesystem->delete($targetPath)) {
            return new DeployedFile(
                relativePath: $relativePath,
                outcome: DeployOutcome::Failed,
                reason: 'the superseded ignore file could not be deleted',
            );
        }

        return new DeployedFile(relativePath: $relativePath, outcome: DeployOutcome::Removed);
    }

    private function withoutManagedBlock(string $currentIgnores): string
    {
        $blockStart = strpos($currentIgnores, self::BLOCK_BEGIN);
        $blockEnd = strpos($currentIgnores, self::BLOCK_END);
        if ($blockStart === false || $blockEnd === false || $blockEnd < $blockStart) {
            return $currentIgnores;
        }

        $blockEnd += strlen(self::BLOCK_END);

        return substr($currentIgnores, 0, $blockStart) . substr($currentIgnores, $blockEnd);
    }
}
