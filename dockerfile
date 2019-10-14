#Use the centos/systemd image
FROM centos/systemd

#Define the maintainer
MAINTAINER "Your Name" <you@example.com>

#Install Apache
RUN yum -y install httpd

#Install Python 3
RUN yum -y install python3 python3-devel

#Install Python module build requirements
RUN yum -y install gcc postgresql postgresql-devel

#Install Python modules
RUN python3 -m pip install bs4 psycopg2 PyYAML

#Configure Apache
COPY docker/python.conf /etc/httpd/conf.d/python.conf

#Setup app files
RUN mkdir -p /var/www/python
COPY ./find_jobs.py /var/www/python/find_jobs.py
COPY ./helper.py /var/www/python/helper.py
COPY ./job_matchmaker.conf /etc/job_matchmaker.conf
COPY ./rate_job.py /var/www/python/rate_job.py
COPY ./search.css /var/www/html/search.css
COPY ./search.html /var/www/html/search.html
COPY ./search.js /var/www/html/search.js
COPY ./show_jobs.py /var/www/python/show_jobs.py
RUN chown apache:apache -R /var/www/python
RUN chown apache:apache /etc/job_matchmaker.conf
RUN chmod 400 /etc/job_matchmaker.conf

#Clear up the Yum cache
RUN yum clean all

#Enable the Apache daemon
RUN systemctl enable httpd.service

#Expose port 80 to the host
EXPOSE 80

#
CMD ["/usr/sbin/init"]