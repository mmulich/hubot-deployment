# Hubot Deployment

## Installs

All installs require the playbook dependencies to be installed, this can be done using the galaxy command.

```sh
ansible-galaxy install --roles-path=./roles -r requirements.yml
```

### Local install

The local install can be invoked using ``vagrant up``. This by default installs all the necessary part for a fully functioning cnx site at production.

You can adjust the provisioning by assigning values to the environment variable ``$playbook`` and/or ``$inventory``. The default playbook is ``site.yml``, which installs a complete self contained production system. The default inventory is ``vagrant-inventory``.

To use these on your host machine, add the following to your ``/etc/hosts`` file:

```
192.168.11.22    hubot.local
```

### Docker install

1. Install ``docker`` and ``docker-compose``.

2. Decrypt ``vars/adapter.yml``:

   ```
ansible-vault decrypt vars/adapter.yml
```

3. Run ``docker-compose up -d``.

## Playbook layout (directory structure)

This project attempts to follow a similar file and directory laid out documented in the Ansible community [best practices](http://docs.ansible.com/playbooks_best_practices.html#directory-layout). Any deviations from the structure are contained in the following documentation.

## License

BSD
