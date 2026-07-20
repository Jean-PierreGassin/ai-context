<?php

namespace JeanPierreGassin\AiContext\Collections;

use ArrayIterator;
use Countable;
use IteratorAggregate;
use JeanPierreGassin\AiContext\Data\DeployedFile;
use JeanPierreGassin\AiContext\Enums\DeployOutcome;
use Traversable;

/**
 * @implements IteratorAggregate<int, DeployedFile>
 */
class DeployedFileCollection implements IteratorAggregate, Countable
{
    /**
     * @var DeployedFile[]
     */
    private readonly array $deployedFiles;

    public function __construct(DeployedFile ...$deployedFiles)
    {
        $this->deployedFiles = $deployedFiles;
    }

    public function merge(self $other): self
    {
        return new self(...$this->deployedFiles, ...$other->deployedFiles);
    }

    public function filterByOutcome(DeployOutcome $outcome): self
    {
        return new self(
            ...array_filter(
                $this->deployedFiles,
                fn (DeployedFile $deployedFile): bool => $deployedFile->outcome === $outcome,
            ),
        );
    }

    /**
     * @return string[]
     */
    public function describeAll(): array
    {
        return array_map(
            fn (DeployedFile $deployedFile): string => $deployedFile->describe(),
            $this->deployedFiles,
        );
    }

    public function getIterator(): Traversable
    {
        return new ArrayIterator($this->deployedFiles);
    }

    public function count(): int
    {
        return count($this->deployedFiles);
    }
}
