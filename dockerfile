#Use the centos/systemd image
FROM centos/systemd

#Define the maintainer
MAINTAINER "Your Name" <you@example.com>

#Install Apache
RUN yum -y install httpd \
#Install Python 3
	python3 python3-devel \
#Install Python module build requirements
	gcc postgresql postgresql-devel \
#Clear the Yum cache
	&& yum -y clean all

#Install Python modules
RUN python3 -m pip install bs4 psycopg2 PyYAML

#Remove unneeded Python package and dependencies
RUN yum -y remove python3-devel dwz groff-base perl perl-Carp perl-Encode perl-Exporter perl-File-Path perl-File-Temp perl-Filter perl-Getopt-Long perl-HTTP-Tiny perl-PathTools perl-Pod-Escapes perl-Pod-Perldoc perl-Pod-Simple perl-Pod-Usage perl-Scalar-List-Utils perl-Socket perl-Storable perl-Text-ParseWords perl-Time-HiRes perl-Time-Local perl-constant perl-libs perl-macros perl-parent perl-podlators perl-srpm-macros perl-threads perl-threads-shared python-rpm-macros python-srpm-macros python3-rpm-generators python3-rpm-macros redhat-rpm-config zip \
#Remove unneeded gcc package and dependencies
	gcc cpp glibc-devel glibc-headers kernel-headers libgomp libmpc mpfr \
#Remove unneeded PostgreSQL package
	postgresql-devel \
#Clear the Yum cache
	&& yum -y clean all

#Configure Apache
COPY docker/python.conf /etc/httpd/conf.d/python.conf

#Setup app files
RUN mkdir -p /var/www/python
COPY ./find_jobs.py /var/www/python/find_jobs.py
COPY ./helper.py /var/www/python/helper.py
COPY docker/job_matchmaker.conf /etc/job_matchmaker.conf
COPY ./rate_job.py /var/www/python/rate_job.py
COPY ./search.css /var/www/html/search.css
COPY ./search.html /var/www/html/search.html
COPY ./search.js /var/www/html/search.js
COPY ./show_jobs.py /var/www/python/show_jobs.py
RUN chown apache:apache -R /var/www/python
RUN chown apache:apache /etc/job_matchmaker.conf
RUN chmod 400 /etc/job_matchmaker.conf

#Clear up the Yum cache
#RUN yum -y clean all

#Enable the Apache daemon
RUN systemctl enable httpd.service

#Expose port 80 to the host
EXPOSE 80

#
CMD ["/usr/sbin/init"]
