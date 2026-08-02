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
    private const OPTION_DRY_RUN = 'dry-run';
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
            self::OPTION_DRY_RUN,
            null,
            InputOption::VALUE_NONE,
            'Report what a full install would change without writing anything',
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

        $isDryRun = $input->getOption(self::OPTION_DRY_RUN) === true;
        try {
            $report = $this->installerFactory
                ->create(
                    approval: $this->resolveApproval($input, $style),
                    isPreview: $isDryRun,
                )
                ->install((string) $input->getOption(self::OPTION_PROJECT_DIR));
        } catch (PayloadNotFoundException $exception) {
            $style->error($exception->getMessage());

            return Command::FAILURE;
        }

        return $this->report($report, $style, $isDryRun);
    }

    /**
     * A dry run never prompts, because there is nothing to approve when
     * nothing is written. It assumes approval instead, so the report
     * covers every file a full install would touch.
     */
    private function resolveApproval(InputInterface $input, SymfonyStyle $style): OverwriteApproval
    {
        $isForced = $input->getOption(self::OPTION_FORCE) === true;
        $isDryRun = $input->getOption(self::OPTION_DRY_RUN) === true;
        if ($isForced || $isDryRun) {
            return new ForcedOverwriteApproval();
        }

        if (!$input->isInteractive()) {
            return new DeclinedOverwriteApproval();
        }

        return new ConsoleOverwriteApproval($style);
    }

    private function report(InstallReport $report, SymfonyStyle $style, bool $isDryRun): int
    {
        $style->table(
            ['Outcome', 'Files'],
            array_map(
                fn (DeployOutcome $outcome): array => [$outcome->label(), $report->countByOutcome($outcome)],
                DeployOutcome::cases(),
            ),
        );

        $notableSkips = $report->listNotableSkips();
        if ($notableSkips->count() > 0) {
            $style->warning('Some files were left alone:');
            $style->listing($notableSkips->describeAll());
        }

        if (!$report->hasFailures()) {
            $successMessage = $isDryRun ? 'Dry run: nothing was written.' : 'Your project is up to date.';
            $style->success($successMessage);

            return Command::SUCCESS;
        }

        $style->error('Some files could not be installed.');
        $style->listing($report->listFailures()->describeAll());

        return Command::FAILURE;
    }
}
