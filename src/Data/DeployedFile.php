<?php

namespace JeanPierreGassin\AiContext\Data;

use JeanPierreGassin\AiContext\Enums\DeployOutcome;

final class DeployedFile
{
    public function __construct(
        public readonly string $relativePath,
        public readonly DeployOutcome $outcome,
        public readonly ?string $reason = null,
    ) {
    }

    public function hasFailed(): bool
    {
        return $this->outcome === DeployOutcome::Failed;
    }

    public function describe(): string
    {
        if ($this->reason === null) {
            return $this->relativePath;
        }

        return "$this->relativePath: $this->reason";
    }
}
