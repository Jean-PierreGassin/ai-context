<?php

namespace JeanPierreGassin\AiContext\Installer;

use JeanPierreGassin\AiContext\Contracts\OverwriteApproval;
use JeanPierreGassin\AiContext\Support\Filesystem;
use JeanPierreGassin\AiContext\Support\PackagePaths;

/**
 * Builds an installer around the approval strategy chosen at runtime,
 * which is only known once the front end has decided whether a human is
 * available to answer prompts.
 */
class ContextInstallerFactory
{
    public function __construct(
        private readonly Filesystem $filesystem,
        private readonly PackagePaths $packagePaths,
    ) {
    }

    public function create(OverwriteApproval $approval): ContextInstaller
    {
        return new ContextInstaller(
            packagePaths: $this->packagePaths,
            payloadDeployer: new PayloadDeployer(filesystem: $this->filesystem, approval: $approval),
            skillIgnoreWriter: new SkillIgnoreWriter(filesystem: $this->filesystem),
            legacyIgnoreCleaner: new LegacyIgnoreCleaner(filesystem: $this->filesystem),
        );
    }
}
