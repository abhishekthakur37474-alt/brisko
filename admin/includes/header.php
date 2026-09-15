<?php

declare(strict_types=1);

$pageTitle = $pageTitle ?? 'Dashboard';
$adminName = $ADMIN['username'] ?? 'admin';
?><!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <title><?= brisko_h($pageTitle) ?> · Brisko Admin</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Poppins:wght@600;700;800&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="assets/css/admin.css" rel="stylesheet">
</head>
<body>
<div class="brisko-shell">
<?php require __DIR__ . '/sidebar.php'; ?>
<div class="brisko-main">
    <header class="brisko-topbar">
        <button class="btn btn-dark d-lg-none" type="button" id="sidebarToggle" aria-label="Open menu">
            <i class="bi bi-list"></i>
        </button>
        <div class="topbar-title">
            <p class="eyebrow mb-0">Brisko Pizza</p>
            <h1><?= brisko_h($pageTitle) ?></h1>
        </div>
        <div class="top-actions">
            <span class="admin-chip"><i class="bi bi-person-circle"></i> <?= brisko_h($adminName) ?></span>
            <a class="btn btn-outline-dark" href="logout.php">Logout</a>
        </div>
    </header>
    <main class="brisko-content">
        <?php require __DIR__ . '/flash.php'; ?>
