<?php

namespace JeanPierreGassin\AiContext\Support;

/**
 * A filesystem that reads from disk as usual but discards every write,
 * so an install can be run for its report alone and leave the project
 * untouched.
 *
 * Discarded writes report success because the caller is describing the
 * outcome a real run would reach, and a write that was never attempted
 * has not failed.
 */
class PreviewFilesystem extends Filesystem
{
    public function ensureDirectory(string $path): bool
    {
        return true;
    }

    public function copy(string $sourcePath, string $targetPath): bool
    {
        return true;
    }

    public function write(string $path, string $contents): bool
    {
        return true;
    }

    public function delete(string $path): bool
    {
        return true;
    }
}
