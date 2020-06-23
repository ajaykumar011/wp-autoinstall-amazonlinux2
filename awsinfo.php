<html>
  <head>
    <title>AWS EC2 PHP Sample</title>
    <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
  </head>
  <body text="blue">
    <h1>Welcome to the AWS EC2 Sample file</h1>
    <p/>
    <?php
      // Print out the current data and time
      print "The Current Date and Time is: <br/>";
      print date("g:i A l, F j Y.");
    ?>
    <p/>
    <?php
      // Setup a handle for CURL
      $curl_handle=curl_init();
      curl_setopt($curl_handle,CURLOPT_CONNECTTIMEOUT,2);
      curl_setopt($curl_handle,CURLOPT_RETURNTRANSFER,1);
      // Get the hostname of the intance from the instance metadata
      curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/public-hostname');
      $hostname = curl_exec($curl_handle);
      if (empty($hostname))
      {
        print "Sorry, for some reason, we got no hostname back <br />";
      }
      else
      {
        print "Server = " . $hostname . "<br />";
      }
      // Get the instance-id of the intance from the instance metadata
      curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/instance-id');
      $instanceid = curl_exec($curl_handle);
      if (empty($instanceid))
      {
        print "Sorry, for some reason, we got no instance id back <br />";
      }
      else
      {
        print "EC2 instance-id = " . $instanceid . "<br />";
      }
	   // Get Metadata intance information.
	   // To get Userdata information we can use this .... curl http://169.254.169.254/latest/user-data
	   
	  curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/instance-type');
      $instancetype = curl_exec($curl_handle);
      print "Instance Type = " . $instancetype . "<br />";
	  
	  
//	  curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/kernel-id');
//      $kernelid = curl_exec($curl_handle);
//      print "Kernel Id = " . $kernelid . "<br />";
	  
      curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/ami-id');
      $amiid = curl_exec($curl_handle);
      print "AMI Id of the instance = " . $amiid . "<br />";
      
	  curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/public-hostname');
      $publichostname = curl_exec($curl_handle);
      print "Public Hostname = " . $publichostname . "<br />";
      
	  curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/block-device-mapping/ami');
      $bdmappingami = curl_exec($curl_handle);
      print "Block Device Mapping (AMI) = " . $blockdevice . "<br />";
      
//	  curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/block-device-mapping/ephemeral0');
//      $bdmappingephemeral = curl_exec($curl_handle);
//      print "Block Device Mapping (Ephemeral) = " . $bdmappingephemeral . "<br />";
      
	  curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/block-device-mapping/root');
      $bdmappingroot = curl_exec($curl_handle);
      print "Block Device Mapping (Root) = " . $bdmappingroot . "<br />";
      
	  curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/local-hostname');
      $localhostname = curl_exec($curl_handle);
      print "Local host name = " . $localhostname . "<br />";
      
	  curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/local-ipv4');
      $localip = curl_exec($curl_handle);
      print "Local IP v4 address = " . $localip . "<br />";
      
	  curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/metrics/');
      $metrics = curl_exec($curl_handle);
      print "Metrices id of Instance = " . $metrics . "<br />";
      
	  curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/placement/availability-zone');
      $az = curl_exec($curl_handle);
      print "Availability Zone = " . $az . "<br />";
      
	  curl_setopt($curl_handle,CURLOPT_URL,'http://169.254.169.254/latest/meta-data/network/interfaces/macs/');
      $macid = curl_exec($curl_handle);
      print "Mac id of Instance = " . $macid . "<br />";
	  
    ?>
<h2>Server IP Address Information</h2>	
<?php
//whether ip is from share internet
if (!empty($_SERVER['HTTP_CLIENT_IP']))   
  {
    $ip_address = $_SERVER['HTTP_CLIENT_IP'];
  }
//whether ip is from proxy
elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR']))  
  {
    $ip_address = $_SERVER['HTTP_X_FORWARDED_FOR'];
  }
//whether ip is from remote address
else
  {
    $ip_address = $_SERVER['REMOTE_ADDR'];
  }
echo $ip_address;
?>	

<h2> System OS information </h2>
<p/>
<?php
echo php_uname();
echo PHP_OS;
echo "<br>";
exec('cat /etc/system-release', $out, $status);
if (0 === $status) {
    var_dump($out);
} else {
    echo "Command failed with status: $status";
}	
?>

    <h2>PHP Information</h2>
    <p/>
    <?php
      phpinfo();
    ?>
  </body>
</html>