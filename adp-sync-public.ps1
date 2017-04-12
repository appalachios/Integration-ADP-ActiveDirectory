

#declare global variable for the workersList
$Global:workerList = New-Object System.Collections.ArrayList

#Contact ADP API support to obtain an authentication key
$authKeyBase64 = "YourADPkey"



#-------------Start of Functions---------------#

#get the certificate that is installed on the local machine for API authentication
function Get-ADPCertificate
{
    $certADP = Get-PfxCertificate -FilePath "C:\OpenSSL-Win64\bin\YourCertificate.pfx"
    $certThumbprint = $certADP.Thumbprint

    return $certThumbprint

}


#authenticate to ADP and receive bearer token
function Get-ADPBearerToken
{
    $certThumbprint = Get-ADPCertificate
    $Headers = @{ Authorization = "Basic " + $authKeyBase64 }
    $tokenRequest = Invoke-RestMethod https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials -CertificateThumbprint $certThumbprint -Headers $Headers -Method Post
    $bearerToken = $tokenRequest.access_token
    
    return $bearerToken
}


#get a count of the number of worker records
function Get-ADPWorkerCount
{
    $countOfWorkers = Invoke-RestMethod "https://api.adp.com/hr/v2/workers?count=true" -CertificateThumbprint $certThumbprint -Headers $Headers 

    return $countOfWorkers.meta.totalnumber
}



#clear the current workersList and pull new worker information from ADP
function Get-ADPworkersArrayList
{
    $totalWorkersCount = Get-ADPWorkerCount #get the total number of worker records in ADP
    $totalRecordsProcessed = 0

    $loopSkip = 1 # We are not skipping any records yet, so we 'skip' to the first record
    
    #set the number of worker records that are obtained during each loop. ADP max is currently 50
    $numberOfWorkerPerLoop = 50

    $workerList.Clear() #clear the arrayList

    #Get worker information
    for($n=0; $totalRecordsProcessed -lt $totalWorkersCount; $n++)
        {
     
            #import data from ADP
            $loopRequest = Invoke-RestMethod "https://api.adp.com/hr/v2/workers?`$top=50&`$skip=$loopSkip" -CertificateThumbprint $certThumbprint -Headers $Headers
    
            $nestedLoopCount = 0 #reset the nested loop count during every run of the parent loop
    
            #add imported data to the arrayList
               for ($c=0; ($c -lt $numberOfWorkerPerLoop) -and ($totalRecordsProcessed -lt $totalWorkersCount); $c++)
                {
                    $workerList.Add($loopRequest.workers[$c])

                    $totalRecordsProcessed++
                }

            $loopskip += $numberOfWorkerPerLoop;
        }

}


#finds a worker and returns their array position
function Find-Worker ($findRequest)
{

    for($n=0; $n -lt $workerList.Count; $n++)
       {

            if ($workerList[$n].person.legalName.familyName1 -eq $findRequest)
            {
                $n
            }

       }

}


#---------------End of Functions---------------#




#---------------Initialize API auth------------#
$bearerToken = Get-ADPbearerToken
$certThumbprint = Get-ADPCertificate

$Headers = @{ Authorization = "Bearer " + $bearerToken }
#----------------------------------------------#


