<?php

namespace JeanPierreGassin\AiContext\Approvals;

use JeanPierreGassin\AiContext\Contracts\OverwriteApproval;

/**
 * Used when no human can answer a prompt, such as a CI run or a
 * container build. Existing files are always left untouched so an
 * unattended install can never destroy local edits.
 */
class DeclinedOverwriteApproval implements OverwriteApproval
{
    public function shouldOverwrite(string $relativePath): bool
    {
        return false;
    }
}
