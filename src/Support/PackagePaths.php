<?php

namespace JeanPierreGassin\AiContext\Support;

use JeanPierreGassin\AiContext\Exceptions\PayloadNotFoundException;

class PackagePaths
{
    private const PAYLOAD_DIRECTORY = 'resources/payload';

    /**
     * @throws PayloadNotFoundException
     */
    public function resolvePayloadRoot(): string
    {
        $payloadRoot = sprintf('%s/%s', $this->resolvePackageRoot(), self::PAYLOAD_DIRECTORY);
        if (!is_dir($payloadRoot)) {
            throw new PayloadNotFoundException(
                sprintf('The ai-context payload is missing from "%s".', $payloadRoot),
            );
        }

        return $payloadRoot;
    }

    public function resolvePackageRoot(): string
    {
        return dirname(__DIR__, 2);
    }
}
