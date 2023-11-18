<?php

$masterConection = new PDO("mysql:host=haproxy;port=3307;dbname=app", "root", "password");
$masterConection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$slaveConnection = new PDO("mysql:host=haproxy;port=3306;dbname=app", "root", "password");
$slaveConnection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$query = "SHOW VARIABLES LIKE 'server_id'";

$masterStmt = $masterConection->prepare($query);
$masterStmt->execute();

$slaveStmt = $slaveConnection->prepare($query);
$slaveStmt->execute();

$masterResult = $masterStmt->fetchAll(PDO::FETCH_ASSOC);
$slaveResult = $slaveStmt->fetchAll(PDO::FETCH_ASSOC);

var_dump("master: ", $masterResult);
var_dump("slave: ", $slaveResult);

