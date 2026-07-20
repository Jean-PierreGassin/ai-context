<?php

namespace JeanPierreGassin\AiContext\Support;

use Composer\IO\IOInterface;
use Composer\Script\Event;
use JeanPierreGassin\AiContext\Approvals\ComposerOverwriteApproval;
use JeanPierreGassin\AiContext\Approvals\DeclinedOverwriteApproval;
use JeanPierreGassin\AiContext\Contracts\OverwriteApproval;
use JeanPierreGassin\AiContext\Exceptions\InstallFailedException;
use JeanPierreGassin\AiContext\Installer\ContextInstallerFactory;

/**
 * Entry point for projects that wire the installer into their own
 * post-install-cmd and post-update-cmd scripts.
 *
 * Composer only accepts a static callable here, so this is the one
 * static seam in the package; it does nothing but assemble the object
 * graph and hand off.
 */
class ComposerScriptHandler
{
    /**
     * @throws InstallFailedException
     */
    public static function install(Event $event): void
    {
        $composerIo = $event->getIO();
        $handler = new self();
        $report = (new ContextInstallerFactory(
            filesystem: new Filesystem(),
            packagePaths: new PackagePaths(),
        ))
            ->create($handler->resolveApproval($composerIo))
            ->install($handler->resolveProjectRoot());

        $composerIo->write(sprintf('ai-context: %s.', $report->summarise()));

        if (!$report->hasFailures()) {
            return;
        }

        $composerIo->writeError($report->listFailures()->describeAll());

        throw new InstallFailedException('ai-context could not install every file.');
    }

    private function resolveApproval(IOInterface $composerIo): OverwriteApproval
    {
        if (!$composerIo->isInteractive()) {
            return new DeclinedOverwriteApproval();
        }

        return new ComposerOverwriteApproval(composerIo: $composerIo);
    }

    private function resolveProjectRoot(): string
    {
        $projectRoot = getcwd();
        if ($projectRoot === false) {
            throw new InstallFailedException('The project directory could not be determined.');
        }

        return $projectRoot;
    }
}
