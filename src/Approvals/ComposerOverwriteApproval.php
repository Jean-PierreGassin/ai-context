<?php

namespace JeanPierreGassin\AiContext\Approvals;

use Composer\IO\IOInterface;
use JeanPierreGassin\AiContext\Contracts\OverwriteApproval;

class ComposerOverwriteApproval implements OverwriteApproval
{
    public function __construct(
        private readonly IOInterface $composerIo,
    ) {
    }

    public function shouldOverwrite(string $relativePath): bool
    {
        return $this->composerIo->askConfirmation(
            sprintf('ai-context: %s differs from the packaged version, overwrite it? [y/N] ', $relativePath),
            false,
        );
    }

    public function shouldAddAgentsImport(string $relativePath): bool
    {
        return $this->composerIo->askConfirmation(
            sprintf(
                'ai-context: %s does not import AGENTS.md, so the packaged guidance will not load. '
                . 'Add the import to the top? [Y/n] ',
                $relativePath,
            ),
            true,
        );
    }
}
