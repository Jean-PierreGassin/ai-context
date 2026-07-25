<?php

namespace JeanPierreGassin\AiContext\Approvals;

use JeanPierreGassin\AiContext\Contracts\OverwriteApproval;
use Symfony\Component\Console\Style\StyleInterface;

class ConsoleOverwriteApproval implements OverwriteApproval
{
    public function __construct(
        private readonly StyleInterface $style,
    ) {
    }

    public function shouldOverwrite(string $relativePath): bool
    {
        return $this->style->confirm(
            sprintf('%s differs from the packaged version, overwrite it?', $relativePath),
            false,
        );
    }

    public function shouldAddAgentsImport(string $relativePath): bool
    {
        return $this->style->confirm(
            sprintf(
                '%s does not import AGENTS.md, so the packaged guidance will not load. Add the import to the top?',
                $relativePath,
            ),
            true,
        );
    }
}
