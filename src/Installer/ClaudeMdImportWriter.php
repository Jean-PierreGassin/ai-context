<?php

namespace JeanPierreGassin\AiContext\Installer;

use JeanPierreGassin\AiContext\Contracts\OverwriteApproval;
use JeanPierreGassin\AiContext\Data\DeployedFile;
use JeanPierreGassin\AiContext\Enums\DeployOutcome;
use JeanPierreGassin\AiContext\Support\Filesystem;

/**
 * Keeps an existing CLAUDE.md pointing at AGENTS.md.
 *
 * Claude Code reads CLAUDE.md and never AGENTS.md, so a project that
 * already had its own CLAUDE.md would otherwise end up with the whole
 * payload on disk and none of it loaded. Overwriting the file would fix
 * the wiring at the cost of the project's own instructions, so the
 * import is prepended and everything already there is kept.
 */
class ClaudeMdImportWriter
{
    public const CLAUDE_MD = 'CLAUDE.md';

    private const IMPORT = '@AGENTS.md';

    public function __construct(
        private readonly Filesystem $filesystem,
        private readonly OverwriteApproval $approval,
    ) {
    }

    /**
     * Returns null when there is no existing file to reconcile, leaving
     * the deployer to install the packaged CLAUDE.md as it normally
     * would.
     */
    public function write(string $projectRoot): ?DeployedFile
    {
        $targetPath = $this->filesystem->joinPaths($projectRoot, self::CLAUDE_MD);
        if (!$this->filesystem->exists($targetPath) || $this->filesystem->isDirectory($targetPath)) {
            return null;
        }

        $existingContents = $this->filesystem->read($targetPath);
        if ($existingContents === null) {
            return new DeployedFile(
                relativePath: self::CLAUDE_MD,
                outcome: DeployOutcome::Failed,
                reason: 'the file could not be read',
            );
        }

        if ($this->importsAgents($existingContents)) {
            return new DeployedFile(relativePath: self::CLAUDE_MD, outcome: DeployOutcome::Unchanged);
        }

        if (!$this->approval->shouldAddAgentsImport(self::CLAUDE_MD)) {
            return new DeployedFile(
                relativePath: self::CLAUDE_MD,
                outcome: DeployOutcome::Skipped,
                reason: 'AGENTS.md is installed but will not load until CLAUDE.md imports it',
            );
        }

        $written = $this->filesystem->write(
            $targetPath,
            self::IMPORT . PHP_EOL . PHP_EOL . ltrim($existingContents, "\r\n"),
        );

        if (!$written) {
            return new DeployedFile(
                relativePath: self::CLAUDE_MD,
                outcome: DeployOutcome::Failed,
                reason: 'the import could not be written',
            );
        }

        return new DeployedFile(relativePath: self::CLAUDE_MD, outcome: DeployOutcome::Installed);
    }

    /**
     * Claude Code skips imports inside code spans and fenced blocks, so
     * a mention of the path in backticks does not count as wiring.
     */
    private function importsAgents(string $contents): bool
    {
        $withoutFencedBlocks = preg_replace('/^```.*?^```/ms', '', $contents) ?? $contents;
        $withoutCodeSpans = preg_replace('/`[^`\n]*`/', '', $withoutFencedBlocks) ?? $withoutFencedBlocks;

        return preg_match('/(^|\s)' . preg_quote(self::IMPORT, '/') . '(\s|$)/m', $withoutCodeSpans) === 1;
    }
}
