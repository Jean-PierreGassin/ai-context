<?php

namespace JeanPierreGassin\AiContext\Contracts;

interface OverwriteApproval
{
    public function shouldOverwrite(string $relativePath): bool;
}
