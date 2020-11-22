FROM pytorch/pytorch:1.7.0-cuda11.0-cudnn8-runtime


RUN pip install --user notebook

# update PATH environment variable
ENV PATH=/root/.local/bin:$PATH

CMD [ "jupyter", "notebook", "--allow-root", "--ip='*'", "--NotebookApp.token=''", "--NotebookApp.password=''" ]
