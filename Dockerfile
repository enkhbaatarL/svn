FROM centos:6.7

# httpd: Apache
# subversion: svn-server
# subversion-devel: header files and linker scripts for subversion libraries 
# mod_dav_svn: Apache configuration directives for serving Subversion repositories
RUN yum -y install httpd && \
    yum -y install subversion subversion-devel mod_dav_svn && \
    yum clean all

# wget, git 설치
RUN yum -y install wget && \
    yum -y install git && \
	yum clean all

# Apache 1.6.x -> 1.7.x 업데이트
# 1. rpmforge-release 다운로드: This package contains apt, yum and smart
#    configuration for the RPMforge RPM Repository, as well as the public
#    GPG keys used to sign them.
# 2. rpmforge-release rpm 설치l
# 3. DAG의 GPG 키 설치
# 4. SVN update 설치
RUN wget http://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el6/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm && \
    rpm -Uvh rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm && \
    rpm --import http://ftp.iij.ad.jp/pub/linux/repoforge/RPM-GPG-KEY.dag.txt && \
	yum -y install --enablerepo=rpmforge-extras subversion

# Repository 생성
RUN mkdir -p /opt/appdata/svnrepo/repositories \
    && cd /opt/appdata/svnrepo/repositories \
	&& svnadmin create svnrepo \
	&& chown -R apache:apache svnrepo

# ViewVC 설치
RUN yum -y --enablerepo=rpmforge install viewvc

# Apache connector for Crowd 소스 다운로드
RUN git clone https://bitbucket.org/atlassianlabs/cwdapache

ADD assets/wandisco-svn.repo /etc/yum.repo.d/

# 빌드를 위한 필수 패키지를 설치합니다
RUN yum -y install autoconf automake curl-devel httpd-devel libtool libxml2-devel subversion-devel curl httpd-devel libtool libxml2 mod_dav_svn

# 소스 빌드
RUN cd cwdapache/ \
    && libtoolize \
    && autoreconf --install \
	&& ./configure \
	&& make \
	&& make install

# ViewVC 기본 설정 파일
ADD assets/viewvc.conf /etc/viewvc/
	
# httpd를 위한 viewvc 설정 파일
ADD assets/svn_viewvc.conf /etc/httpd/conf.d/

# SVN ACL 설정 파일
ADD assets/svn_access_file /opt/appdata/svnrepo/conf/

EXPOSE 80

ADD run-httpd.sh /run-httpd.sh
RUN chmod -v +x /run-httpd.sh

CMD ["/run-httpd.sh"]