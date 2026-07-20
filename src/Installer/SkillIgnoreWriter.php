<?php

namespace JeanPierreGassin\AiContext\Installer;

use JeanPierreGassin\AiContext\Collections\DeployedFileCollection;
use JeanPierreGassin\AiContext\Data\DeployedFile;
use JeanPierreGassin\AiContext\Enums\DeployOutcome;
use JeanPierreGassin\AiContext\Support\Filesystem;

/**
 * Drops a self-contained .gitignore inside each packaged skill so the
 * skill directory, including that ignore file, stays out of the
 * project's history.
 *
 * Keeping the rule inside the skill rather than in a shared list one
 * level up means adding or removing a skill never produces a diff the
 * project has to commit.
 */
class SkillIgnoreWriter
{
    private const SKILLS_DIRECTORY = 'skills';
    private const IGNORE_FILENAME = '.gitignore';
    private const IGNORE_CONTENTS = <<<'GITIGNORE'
        # Installed and owned by ai-context. Ignores this file too.
        *

        GITIGNORE;

    public function __construct(
        private readonly Filesystem $filesystem,
    ) {
    }

    public function write(string $payloadRoot, string $projectRoot, string $agentDirectory): DeployedFileCollection
    {
        $skillsRoot = $this->filesystem->joinPaths($payloadRoot, $agentDirectory, self::SKILLS_DIRECTORY);

        return new DeployedFileCollection(
            ...array_map(
                fn (string $skillName): DeployedFile => $this->writeSkillIgnore(
                    projectRoot: $projectRoot,
                    agentDirectory: $agentDirectory,
                    skillName: $skillName,
                ),
                $this->filesystem->listDirectoryNames($skillsRoot),
            ),
        );
    }

    private function writeSkillIgnore(string $projectRoot, string $agentDirectory, string $skillName): DeployedFile
    {
        $relativePath = $this->filesystem->joinPaths(
            $agentDirectory,
            self::SKILLS_DIRECTORY,
            $skillName,
            self::IGNORE_FILENAME,
        );
        $targetPath = $this->filesystem->joinPaths($projectRoot, $relativePath);
        if ($this->filesystem->read($targetPath) === self::IGNORE_CONTENTS) {
            return new DeployedFile(relativePath: $relativePath, outcome: DeployOutcome::Unchanged);
        }

        if (!$this->filesystem->ensureDirectory(dirname($targetPath))) {
            return new DeployedFile(
                relativePath: $relativePath,
                outcome: DeployOutcome::Failed,
                reason: sprintf('could not create the "%s" skill directory', $skillName),
            );
        }

        if (!$this->filesystem->write($targetPath, self::IGNORE_CONTENTS)) {
            return new DeployedFile(
                relativePath: $relativePath,
                outcome: DeployOutcome::Failed,
                reason: 'the ignore file could not be written',
            );
        }

        return new DeployedFile(relativePath: $relativePath, outcome: DeployOutcome::Installed);
    }
}
