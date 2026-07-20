<?php

namespace JeanPierreGassin\AiContext\Installer;

use JeanPierreGassin\AiContext\Collections\DeployedFileCollection;
use JeanPierreGassin\AiContext\Contracts\OverwriteApproval;
use JeanPierreGassin\AiContext\Data\DeployedFile;
use JeanPierreGassin\AiContext\Enums\DeployOutcome;
use JeanPierreGassin\AiContext\Support\Filesystem;

/**
 * Mirrors the packaged payload into a project, one file at a time.
 *
 * Files are copied rather than symlinked so a project can edit them in
 * place, and anything that already differs is only replaced once the
 * injected approval says so.
 */
class PayloadDeployer
{
    public function __construct(
        private readonly Filesystem $filesystem,
        private readonly OverwriteApproval $approval,
    ) {
    }

    public function deploy(string $payloadRoot, string $projectRoot): DeployedFileCollection
    {
        return new DeployedFileCollection(
            ...array_map(
                fn (string $relativePath): DeployedFile => $this->deployFile(
                    payloadRoot: $payloadRoot,
                    projectRoot: $projectRoot,
                    relativePath: $relativePath,
                ),
                $this->filesystem->listRelativeFilePaths($payloadRoot),
            ),
        );
    }

    private function deployFile(string $payloadRoot, string $projectRoot, string $relativePath): DeployedFile
    {
        $sourcePath = $this->filesystem->joinPaths($payloadRoot, $relativePath);
        $targetPath = $this->filesystem->joinPaths($projectRoot, $relativePath);
        if (!$this->filesystem->ensureDirectory(dirname($targetPath))) {
            return new DeployedFile(
                relativePath: $relativePath,
                outcome: DeployOutcome::Failed,
                reason: sprintf('could not create the "%s" directory', dirname($relativePath)),
            );
        }

        if (!$this->filesystem->exists($targetPath)) {
            return $this->copyFile(sourcePath: $sourcePath, targetPath: $targetPath, relativePath: $relativePath);
        }

        return $this->replaceFile(sourcePath: $sourcePath, targetPath: $targetPath, relativePath: $relativePath);
    }

    private function replaceFile(string $sourcePath, string $targetPath, string $relativePath): DeployedFile
    {
        if ($this->filesystem->hasIdenticalContent($sourcePath, $targetPath)) {
            return new DeployedFile(relativePath: $relativePath, outcome: DeployOutcome::Unchanged);
        }

        if ($this->filesystem->isDirectory($targetPath)) {
            return new DeployedFile(
                relativePath: $relativePath,
                outcome: DeployOutcome::Failed,
                reason: 'a directory already exists at this path',
            );
        }

        if (!$this->approval->shouldOverwrite($relativePath)) {
            return new DeployedFile(relativePath: $relativePath, outcome: DeployOutcome::Skipped);
        }

        return $this->copyFile(sourcePath: $sourcePath, targetPath: $targetPath, relativePath: $relativePath);
    }

    private function copyFile(string $sourcePath, string $targetPath, string $relativePath): DeployedFile
    {
        if (!$this->filesystem->copy($sourcePath, $targetPath)) {
            return new DeployedFile(
                relativePath: $relativePath,
                outcome: DeployOutcome::Failed,
                reason: 'the file could not be written',
            );
        }

        return new DeployedFile(relativePath: $relativePath, outcome: DeployOutcome::Installed);
    }
}
