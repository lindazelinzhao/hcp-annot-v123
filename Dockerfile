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

USER $NB_USER

# Install some stuff...
RUN conda update --yes -n base conda && conda install --yes py4j nibabel s3fs
RUN conda install --yes -c conda-forge ipywidgets
RUN pip install --upgrade setuptools
RUN pip install 'ipyvolume>=0.5.1'

RUN git clone https://github.com/noahbenson/neuropythy \
 && cd neuropythy \
 && pip install -r requirements.txt \
 && pip install matplotlib \
 && python setup.py install

RUN mkdir -p /home/$NB_USER/.jupyter
COPY docker/jupyter_notebook_config.py /home/$NB_USER/.jupyter/

# Install collapsible cell extensions...
RUN conda install -c conda-forge jupyter_contrib_nbextensions
RUN jupyter contrib nbextension install --user
RUN jupyter nbextension enable collapsible_headings/main \
 && jupyter nbextension enable select_keymap/main

# The root operations ...
USER root

# Install curl
RUN apt-get update && apt-get install --yes curl
# Make some directories
RUN mkdir /data && mkdir /save && chown $NB_USER /data /save && chmod 755 /data /save

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

# Remove the work directory and hide neuropythy
RUN rmdir /home/$NB_USER/work \
 && mv /home/$NB_USER/neuropythy /home/$NB_USER/.neuropythy

# Reconfigure Jupyter a bit
RUN mkdir -p ~/.jupyter/custom
COPY docker/custom.css /home/$NB_USER/.jupyter/custom/
COPY docker/custom.js /home/$NB_USER/.jupyter/custom/
COPY docker/ipython-startup.py /home/$NB_USER/.ipython/profile_default/startup/
COPY docker/ipython_kernel_config.py /home/$NB_USER/.ipython/profile_default/
COPY work/roi-drawing.ipynb /home/$NB_USER/open_me.ipynb

USER root
RUN chown -R $NB_USER /home/$NB_USER/.ipython && chmod 700 /home/$NB_USER/.ipython
RUN mkdir -p /opt/ext/python
USER $NB_USER

# And mark it as the entrypoint
ENTRYPOINT ["tini", "-g", "--", "/usr/local/bin/start-notebook.sh"]

