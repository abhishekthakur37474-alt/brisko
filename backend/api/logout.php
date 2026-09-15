<?php

declare(strict_types=1);

require_once __DIR__ . '/../helpers/bootstrap.php';

require_post();

// The app keeps no long-lived server session: Firebase holds the auth state and
// the client signs out locally. This endpoint exists so the flow stays
// symmetric and can later clear server-side artefacts (tokens, logs, etc.).
json_response([
    'success' => true,
    'message' => 'Logged out successfully',
]);
