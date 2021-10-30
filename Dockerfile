# This Dockerfile constructs a docker image that contains an installation
# of the Neuropythy library for use with the HCP-annotation project.
#
# Example build:
#   docker build --no-cache --tag hcp-annotate `pwd`
#
#   (but really, use docker-compose up instead).
#

# Start with the Ubuntu for now
FROM jupyter/scipy-notebook

# Note the Maintainer.
MAINTAINER Noah C. Benson <nben@uw.edu>

# Install some stuff...
RUN conda update --yes -n base conda && conda install --yes py4j nibabel s3fs
RUN conda install --yes -c conda-forge ipywidgets
RUN pip install --upgrade setuptools
RUN pip install 'ipyvolume>=0.5.1'

RUN git clone https://github.com/noahbenson/neuropythy\
 && cd neuropythy \
 && pip install -r requirements-dev.txt \
 && python setup.py install

RUN mkdir -p /home/$NB_USER/.jupyter \
 && cp /home/$NB_USER/neuropythy/docker/jupyter_notebook_config.py /home/$NB_USER/.jupyter/

# Install collapsible cell extensions...
RUN conda install -c conda-forge jupyter_contrib_nbextensions
RUN jupyter contrib nbextension install --user
RUN jupyter nbextension enable collapsible_headings/main \
 && jupyter nbextension enable select_keymap/main

# The root operations ...
USER root

# Make sure we have the run.sh script ready:
RUN cp /home/$NB_USER/neuropythy/docker/main.sh /main.sh \
 && cp /home/$NB_USER/neuropythy/docker/help.txt /help.txt \
 && chmod 755 /main.sh /help.txt

USER $NB_USER

# As the use (now with curl!), install the helvetica neue font (for figures)
RUN mkdir -p ~/.local/share/fonts/helvetica_neue_tmp
RUN curl -L -o ~/.local/share/fonts/helvetica_neue_tmp/helveticaneue.zip \
         https://github.com/noahbenson/neuropythy/wiki/files/helveticaneue.zip
RUN cd ~/.local/share/fonts/helvetica_neue_tmp \
 && unzip helveticaneue.zip \
 && mv *.ttf .. \
 && cd .. \
 && rm -r ~/.local/share/fonts/helvetica_neue_tmp
RUN fc-cache -f -v
RUN rm -r ~/.cache/matplotlib

# And mark it as the entrypoint
#CMD ["/main.sh"]
ENTRYPOINT ["tini", "-g", "--", "/main.sh"]
