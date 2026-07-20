<?php

namespace JeanPierreGassin\AiContext\Enums;

enum DeployOutcome: string
{
    case Installed = 'installed';
    case Unchanged = 'unchanged';
    case Skipped = 'skipped';
    case Removed = 'removed';
    case Failed = 'failed';

    public function label(): string
    {
        return match ($this) {
            self::Installed => 'Installed',
            self::Unchanged => 'Unchanged',
            self::Skipped => 'Skipped',
            self::Removed => 'Removed',
            self::Failed => 'Failed',
        };
    }
}
