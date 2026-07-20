<?php

namespace JeanPierreGassin\AiContext\Approvals;

use JeanPierreGassin\AiContext\Contracts\OverwriteApproval;

class ForcedOverwriteApproval implements OverwriteApproval
{
    public function shouldOverwrite(string $relativePath): bool
    {
        return true;
    }
}
