<?php

namespace JeanPierreGassin\AiContext\Contracts;

interface OverwriteApproval
{
    public function shouldOverwrite(string $relativePath): bool;

    /**
     * Asked when a project already has its own CLAUDE.md that never
     * imports AGENTS.md, which leaves the packaged guidance on disk but
     * unread. Answering yes prepends the import and keeps the rest of
     * the file, so this never costs a project its own instructions.
     */
    public function shouldAddAgentsImport(string $relativePath): bool;
}
