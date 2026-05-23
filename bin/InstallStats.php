<?php

namespace JeanPierreGassin\AiContext;

final class InstallStats
{
    private int $installed = 0;
    private int $skipped = 0;
    private int $failed = 0;

    public function getInstalled(): int
    {
        return $this->installed;
    }

    public function getSkipped(): int
    {
        return $this->skipped;
    }

    public function getFailed(): int
    {
        return $this->failed;
    }

    public function incrementInstalled(): void
    {
        $this->installed++;
    }

    public function incrementSkipped(): void
    {
        $this->skipped++;
    }

    public function incrementFailed(): void
    {
        $this->failed++;
    }
}
