FROM pytorch/pytorch:1.8.1-cuda11.1-cudnn8-runtime


RUN pip install --user notebook

# update PATH environment variable
ENV PATH=/root/.local/bin:$PATH

CMD [ "jupyter", "notebook", "--allow-root", "--ip='*'", "--NotebookApp.token=''", "--NotebookApp.password=''" ]
