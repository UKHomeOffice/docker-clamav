# Example use in Kubernetes

## Example POD with two processes

This example will create a single POD with two containers:

* clamd - will run the api
* freshclam - will ensure the api has upto date virus definitions

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: clamav
  labels:
    name: clamav
spec:
  replicas: 1
  selector:
    name: clamav
  template:
    metadata:
      labels:
        name: clamav
    spec:
      containers:
      - name: clamd
        image: quay.io/ukhomeofficedigital/clamav:v1.6.1
        env:
        - name: UPDATE
          value: "false"
        ports:
        - containerPort: 3200
          name: api
          protocol: TCP
        volumeMounts:
          - mountPath: /var/lib/clamav
            name: avdata
        livenessProbe:
          exec:
            command:
            - /readyness.sh
          initialDelaySeconds: 20
          timeoutSeconds: 2
      - name: freshclam
        image: quay.io/ukhomeofficedigital/clamav:v1.6.1
        env:
        - name: UPDATE_ONLY
          value: "true"
        volumeMounts:
        - mountPath: /var/lib/clamav
          name: avdata
        livenessProbe:
          exec:
            command:
            - /readyness.sh
          initialDelaySeconds: 20
          timeoutSeconds: 2
      volumes:
      - name: avdata
        emptyDir: {}
```
