<?php

namespace JeanPierreGassin\AiContext\Console;

use JeanPierreGassin\AiContext\Installer\ContextInstallerFactory;
use JeanPierreGassin\AiContext\Support\Filesystem;
use JeanPierreGassin\AiContext\Support\PackagePaths;
use JeanPierreGassin\AiContext\Support\PackageVersion;
use Symfony\Component\Console\Application as ConsoleApplication;

class Application extends ConsoleApplication
{
    private const NAME = 'ai-context';

    public function __construct()
    {
        parent::__construct(self::NAME, (new PackageVersion())->resolve());

        $installerFactory = new ContextInstallerFactory(
            filesystem: new Filesystem(),
            packagePaths: new PackagePaths(),
        );

        $this->add(new InstallCommand(installerFactory: $installerFactory));
        $this->setDefaultCommand('install');
    }
}
