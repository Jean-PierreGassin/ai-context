<?php

namespace JeanPierreGassin\AiContext\Support;

use Composer\InstalledVersions;
use OutOfBoundsException;

/**
 * Reads the version Composer resolved for this package, which comes
 * from the release tag it was installed against.
 *
 * Falls back to a placeholder when the package is being run from a
 * checkout rather than from a consuming project's vendor directory.
 */
class PackageVersion
{
    private const PACKAGE_NAME = 'jean-pierre-gassin/ai-context';
    private const FALLBACK_VERSION = 'dev';

    public function resolve(): string
    {
        if (!class_exists(InstalledVersions::class) || !InstalledVersions::isInstalled(self::PACKAGE_NAME)) {
            return self::FALLBACK_VERSION;
        }

        try {
            return InstalledVersions::getPrettyVersion(self::PACKAGE_NAME) ?? self::FALLBACK_VERSION;
        } catch (OutOfBoundsException) {
            return self::FALLBACK_VERSION;
        }
    }
}
