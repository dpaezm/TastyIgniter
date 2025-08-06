<?php

namespace Gridded\ApiReservationExtension;

use Igniter\System\Classes\BaseExtension;      // ⬅️  CORREGIDO
use Igniter\System\Classes\RouteRegistrar;     // ⬅️  CORREGIDO

class Extension extends BaseExtension
{
    public function register() {}
    public function boot() {}

    public function registerRoutes()
    {
        RouteRegistrar::instance()
            ->registerRoutesFromFile(__DIR__.'/routes.php');
    }
}
