<?php

namespace JeanPierreGassin\AiContext\Data;

use JeanPierreGassin\AiContext\Collections\DeployedFileCollection;
use JeanPierreGassin\AiContext\Enums\DeployOutcome;

final class InstallReport
{
    public function __construct(
        public readonly DeployedFileCollection $deployedFiles,
    ) {
    }

    public function countByOutcome(DeployOutcome $outcome): int
    {
        return $this->deployedFiles->filterByOutcome($outcome)->count();
    }

    public function listFailures(): DeployedFileCollection
    {
        return $this->deployedFiles->filterByOutcome(DeployOutcome::Failed);
    }

    public function hasFailures(): bool
    {
        return $this->listFailures()->count() > 0;
    }

    public function summarise(): string
    {
        return sprintf(
            'installed %d, unchanged %d, skipped %d, failed %d',
            $this->countByOutcome(DeployOutcome::Installed),
            $this->countByOutcome(DeployOutcome::Unchanged),
            $this->countByOutcome(DeployOutcome::Skipped),
            $this->countByOutcome(DeployOutcome::Failed),
        );
    }
}
