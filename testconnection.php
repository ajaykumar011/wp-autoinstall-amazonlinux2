<?php
$link = mysqli_connect('cloudzone-db.cs9oerabvh9z.ap-south-1.rds.amazonaws.com', 'cloudz_wpusr1', 'Techno%oint$1');
if (!$link) {
die('Could not connect: ' . mysqli_error());
}
echo 'Connected successfully';
mysqli_close($link);
?>