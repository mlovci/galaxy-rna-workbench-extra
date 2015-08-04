
# Galaxy - RNA workbench
#
# VERSION       0.1

FROM bgruening/galaxy-rna-workbench

#mostly from galaxy-rna-workbench-extra by bgreuning
MAINTAINER Michael Lovci; michaeltlovci@gmail.com

ENV GALAXY_CONFIG_BRAND RNA workbench

WORKDIR /galaxy-central


# TODO: rnashapes is currently not in the ToolShed install it via PPA
RUN apt-get -qq update && apt-get install --no-install-recommends -y apt-transport-https software-properties-common && \
    apt-add-repository -y ppa:bibi-help/bibitools && \
    apt-get -qq update && \
    apt-get install --no-install-recommends -y rnashapes && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    . /home/galaxy/venv/bin/activate
RUN easy_install -U pip
RUN sudo pip install --upgrade setuptools && \
    sudo pip install --upgrade pulsar-app && \
    sudo pip install --upgrade bioblend

RUN mkdir /etc/ssl/private-copy; mv /etc/ssl/private/* /etc/ssl/private-copy/; rm -r /etc/ssl/private; mv /etc/ssl/private-copy /etc/ssl/private; chmod -R 0700 /etc/ssl/private; chown -R postgres /etc/ssl/private

RUN install-repository "--url https://toolshed.g2.bx.psu.edu/ -o devteam --name data_manager_fetch_genome_all_fasta" \
    "--url https://toolshed.g2.bx.psu.edu/ -o devteam --name package_bowtie2_2_1_0" \
    "--url https://toolshed.g2.bx.psu.edu/ -o devteam --name bowtie2 --panel-section-name RNATools" \
    "--url https://toolshed.g2.bx.psu.edu/ -o iuc --name package_gnu_awk_4_1_0" \
    "--url https://toolshed.g2.bx.psu.edu/ -o iuc --name package_gnu_grep_2_14" \
    "--url https://toolshed.g2.bx.psu.edu/ -o iuc --name package_gnu_sed_4_2_2_sandbox" \
    "--url https://toolshed.g2.bx.psu.edu/ -o bgruening --name text_processing --panel-section-id textutil" \
    '--url https://toolshed.g2.bx.psu.edu/ -o iuc --name bedtools --panel-section-name BED-Tools' \
    "--url https://toolshed.g2.bx.psu.edu/ -o devteam --name emboss_5 --panel-section-name EMBOSS" \
    "--url https://toolshed.g2.bx.psu.edu/ -o devteam --name data_manager_bowtie2_index_builder"  


# modified supervisor conf file
ADD galaxy_build.conf /etc/galaxy/
ADD galaxy_build.ini /etc/galaxy/

# starts a galaxy instance for build process
ADD start_galaxy_for_build /usr/bin/
RUN chmod +x /usr/bin/start_galaxy_for_build

# specifies files to include as data libraries
ADD setup_data_libraries.py /galaxy-central/

ENV GALAXY_CONFIG_JOB_WORKING_DIRECTORY=/galaxy-central/database/job_working_directory \
    GALAXY_CONFIG_FILE_PATH=/galaxy-central/database/files \
    GALAXY_CONFIG_NEW_FILE_PATH=/galaxy-central/database/files \
    GALAXY_CONFIG_TEMPLATE_CACHE_PATH=/galaxy-central/database/compiled_templates \
    GALAXY_CONFIG_CITATION_CACHE_DATA_DIR=/galaxy-central/database/citations/data \
    GALAXY_CONFIG_CLUSTER_FILES_DIRECTORY=/galaxy-central/database/pbs \
    GALAXY_CONFIG_FTP_UPLOAD_DIR=/galaxy-central/database/ftp \
    GALAXY_CONFIG_INTEGRATED_TOOL_PANEL_CONFIG=/galaxy-central/integrated_tool_panel.xml \
    GALAXY_CONFIG_ALLOW_LIBRARY_PATH_PASTE=True

ADD build_job_conf.xml /etc/galaxy/
ENV GALAXY_CONFIG_JOB_CONFIG_FILE /etc/galaxy/build_job_conf.xml

RUN start_galaxy_for_build && python -u setup_data_libraries.py --verbose && supervisorctl stop all && service supervisor stop
# download and index genomes
#ADD fetch_and_index_genomes.ini /galaxy-central/
#ADD fetch_and_index_genomes.py /galaxy-central/

#RUN start_galaxy_for_build && . $GALAXY_VIRTUALENV/bin/activate \
#    && python -u fetch_and_index_genomes.py --config fetch_and_index_genomes.ini --verbose && supervisorctl stop all && service supervisor stop

#ENV GALAXY_CONFIG_JOB_CONFIG_FILE $GALAXY_CONFIG_DIR/job_conf.xml

#ENV GALAXY_CONFIG_JOB_WORKING_DIRECTORY=/export/galaxy-central/database/job_working_directory \
#    GALAXY_CONFIG_FILE_PATH=/export/galaxy-central/database/files \
#    GALAXY_CONFIG_NEW_FILE_PATH=/export/galaxy-central/database/files \
#    GALAXY_CONFIG_TEMPLATE_CACHE_PATH=/export/galaxy-central/database/compiled_templates \
#    GALAXY_CONFIG_CITATION_CACHE_DATA_DIR=/export/galaxy-central/database/citations/data \
#    GALAXY_CONFIG_CLUSTER_FILES_DIRECTORY=/export/galaxy-central/database/pbs \
#    GALAXY_CONFIG_FTP_UPLOAD_DIR=/export/galaxy-central/database/ftp \
#    GALAXY_CONFIG_INTEGRATED_TOOL_PANEL_CONFIG=/export/galaxy-central/integrated_tool_panel.xml


## Change the standard IPython notebook to galaxy-ipython-stable
#RUN sed 's|image =.*|image = bgruening/galaxy-ipython-notebook-plus|g' config/plugins/interactive_environments/ipython/config/ipython.ini.sample >  config/plugins/interactive_environments/ipython/config/ipython.ini


