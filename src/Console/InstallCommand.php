<?php

namespace JeanPierreGassin\AiContext\Console;

use JeanPierreGassin\AiContext\Approvals\ConsoleOverwriteApproval;
use JeanPierreGassin\AiContext\Approvals\DeclinedOverwriteApproval;
use JeanPierreGassin\AiContext\Approvals\ForcedOverwriteApproval;
use JeanPierreGassin\AiContext\Contracts\OverwriteApproval;
use JeanPierreGassin\AiContext\Data\InstallReport;
use JeanPierreGassin\AiContext\Enums\DeployOutcome;
use JeanPierreGassin\AiContext\Exceptions\PayloadNotFoundException;
use JeanPierreGassin\AiContext\Installer\ContextInstallerFactory;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'install',
    description: 'Install the agent context, skills, and harness configuration into a project',
)]
class InstallCommand extends Command
{
    private const OPTION_FORCE = 'force';
    private const OPTION_PROJECT_DIR = 'project-dir';

    public function __construct(
        private readonly ContextInstallerFactory $installerFactory,
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this->addOption(
            self::OPTION_FORCE,
            'f',
            InputOption::VALUE_NONE,
            'Overwrite locally modified files without asking',
        );
        $this->addOption(
            self::OPTION_PROJECT_DIR,
            null,
            InputOption::VALUE_REQUIRED,
            'The project to install into',
            getcwd() ?: '.',
        );
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $style = new SymfonyStyle($input, $output);
        $style->title('ai-context');

        try {
            $report = $this->installerFactory
                ->create($this->resolveApproval($input, $style))
                ->install((string) $input->getOption(self::OPTION_PROJECT_DIR));
        } catch (PayloadNotFoundException $exception) {
            $style->error($exception->getMessage());

            return Command::FAILURE;
        }

        return $this->report($report, $style);
    }

    private function resolveApproval(InputInterface $input, SymfonyStyle $style): OverwriteApproval
    {
        if ($input->getOption(self::OPTION_FORCE) === true) {
            return new ForcedOverwriteApproval();
        }

        if (!$input->isInteractive()) {
            return new DeclinedOverwriteApproval();
        }

        return new ConsoleOverwriteApproval($style);
    }

    private function report(InstallReport $report, SymfonyStyle $style): int
    {
        $style->table(
            ['Outcome', 'Files'],
            array_map(
                fn (DeployOutcome $outcome): array => [$outcome->label(), $report->countByOutcome($outcome)],
                DeployOutcome::cases(),
            ),
        );

        if (!$report->hasFailures()) {
            $style->success('Your project is up to date.');

            return Command::SUCCESS;
        }

        $style->error('Some files could not be installed.');
        $style->listing($report->listFailures()->describeAll());

        return Command::FAILURE;
    }
}
