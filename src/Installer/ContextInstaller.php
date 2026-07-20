<?php

namespace JeanPierreGassin\AiContext\Installer;

use JeanPierreGassin\AiContext\Collections\DeployedFileCollection;
use JeanPierreGassin\AiContext\Data\DeployedFile;
use JeanPierreGassin\AiContext\Data\InstallReport;
use JeanPierreGassin\AiContext\Exceptions\PayloadNotFoundException;
use JeanPierreGassin\AiContext\Support\PackagePaths;

class ContextInstaller
{
    private const AGENT_DIRECTORIES = ['.agents', '.claude'];

    public function __construct(
        private readonly PackagePaths $packagePaths,
        private readonly PayloadDeployer $payloadDeployer,
        private readonly SkillIgnoreWriter $skillIgnoreWriter,
        private readonly LegacyIgnoreCleaner $legacyIgnoreCleaner,
    ) {
    }

    /**
     * @throws PayloadNotFoundException
     */
    public function install(string $projectRoot): InstallReport
    {
        $payloadRoot = $this->packagePaths->resolvePayloadRoot();
        $projectRoot = rtrim($projectRoot, DIRECTORY_SEPARATOR);
        $deployedFiles = $this->payloadDeployer->deploy($payloadRoot, $projectRoot);

        return new InstallReport(
            $deployedFiles
                ->merge($this->writeSkillIgnores($payloadRoot, $projectRoot))
                ->merge($this->cleanLegacyIgnores($projectRoot)),
        );
    }

    private function writeSkillIgnores(string $payloadRoot, string $projectRoot): DeployedFileCollection
    {
        return array_reduce(
            self::AGENT_DIRECTORIES,
            fn (DeployedFileCollection $written, string $agentDirectory): DeployedFileCollection => $written->merge(
                $this->skillIgnoreWriter->write(
                    payloadRoot: $payloadRoot,
                    projectRoot: $projectRoot,
                    agentDirectory: $agentDirectory,
                ),
            ),
            new DeployedFileCollection(),
        );
    }

    private function cleanLegacyIgnores(string $projectRoot): DeployedFileCollection
    {
        $cleanedIgnores = array_map(
            fn (string $agentDirectory): ?DeployedFile => $this->legacyIgnoreCleaner->clean(
                projectRoot: $projectRoot,
                agentDirectory: $agentDirectory,
            ),
            self::AGENT_DIRECTORIES,
        );

        return new DeployedFileCollection(
            ...array_filter($cleanedIgnores, fn (?DeployedFile $cleaned): bool => $cleaned !== null),
        );
    }
}
