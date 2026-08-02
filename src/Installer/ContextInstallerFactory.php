<?php

namespace JeanPierreGassin\AiContext\Installer;

use JeanPierreGassin\AiContext\Contracts\OverwriteApproval;
use JeanPierreGassin\AiContext\Support\Filesystem;
use JeanPierreGassin\AiContext\Support\PackagePaths;
use JeanPierreGassin\AiContext\Support\PreviewFilesystem;

/**
 * Builds an installer around the approval strategy chosen at runtime,
 * which is only known once the front end has decided whether a human is
 * available to answer prompts.
 *
 * A preview install is the same object graph over a filesystem that
 * discards writes, so the run a front end previews and the run it
 * performs decide every outcome the same way.
 */
class ContextInstallerFactory
{
    public function __construct(
        private readonly Filesystem $filesystem,
        private readonly PackagePaths $packagePaths,
    ) {
    }

    public function create(OverwriteApproval $approval, bool $isPreview = false): ContextInstaller
    {
        $filesystem = $isPreview ? new PreviewFilesystem() : $this->filesystem;

        return new ContextInstaller(
            packagePaths: $this->packagePaths,
            payloadDeployer: new PayloadDeployer(filesystem: $filesystem, approval: $approval),
            skillIgnoreWriter: new SkillIgnoreWriter(filesystem: $filesystem),
            legacyIgnoreCleaner: new LegacyIgnoreCleaner(filesystem: $filesystem),
            claudeMdImportWriter: new ClaudeMdImportWriter(filesystem: $filesystem, approval: $approval),
        );
    }
}
