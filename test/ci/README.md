* Copy `test/ci/vars.yml.sample` to `test/ci/inventory/vars.yml`
* Adjust it your liking
* Provision instances via `ansible-playbook -vv -i test/ci/inventory/ test/ci/launch.yml -e @test/ci/inventory/vars.yml`
  This would place inventory file in `test/ci/inventory/hosts`

* Use created inventory to run prerequisites and deploy:
  ```
  ansible-playbook -vv -i test/ci/inventory/hosts playbooks/prerequisites.yml
  ansible-playbook -vv -i test/ci/inventory/hosts playbooks/deploy_cluster.yml
  ```

* Once the setup is complete run `ansible-playbook -vv -i test/ci/inventory/ test/ci/deprovision.yml`
