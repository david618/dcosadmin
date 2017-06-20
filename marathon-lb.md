# Marathon-LB 

## Increase Timeout

Following Instructions [here](https://mesosphere.com/blog/2015/12/13/service-discovery-and-load-balancing-with-dcos-and-marathon-lb-part-2/)

Created a template an placed it [here](https://s3-us-west-2.amazonaws.com/javierprivaterepotest-exhibitors3bucket-5lq1zz1d7lbg/templates.tgz)

This can be added to an existing Marathon-LB deployment by adding this uri: https://s3-us-west-2.amazonaws.com/javierprivaterepotest-exhibitors3bucket-5lq1zz1d7lbg/templates.tgz

Looks like this in Task Json

<pre>
"uris":["https://s3-us-west-2.amazonaws.com/javierprivaterepotest-exhibitors3bucket-5lq1zz1d7lbg/templates.tgz"]
</pre>
