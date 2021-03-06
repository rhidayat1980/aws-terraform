#this_make := $(lastword $(MAKEFILE_LIST))
#$(warning $(this_make))

admiral: etcd plan_admiral
	cd $(BUILD); $(TF_APPLY);
	$(MAKE) upload_admiral_key
	@$(MAKE) get_etcd_ips
	@$(MAKE) get_admiral_ips

plan_admiral: init_admiral
	cd $(BUILD); $(TF_GET); $(TF_PLAN)

clean_admiral:
	rm -f $(BUILD)/admiral*.tf

create_admiral_key:
	cd $(BUILD); \
		$(SCRIPTS)/aws-keypair.sh -c $(CLUSTER_NAME)-admiral;

upload_admiral_key:
	cd $(BUILD); \
		$(SCRIPTS)/aws-keypair.sh -u $(CLUSTER_NAME)-admiral;

destroy_admiral_key:
	cd $(BUILD); $(SCRIPTS)/aws-keypair.sh -d $(CLUSTER_NAME)-admiral;

plan_destroy_admiral:
	$(eval TMP := $(shell mktemp -d -t admiral ))
	mv $(BUILD)/admiral*.tf $(TMP)
	cd $(BUILD); $(TF_PLAN)
	mv  $(TMP)/admiral*.tf $(BUILD)
	rmdir $(TMP)

destroy_admiral: destroy_admiral_key clean_admiral
	cd $(BUILD); $(TF_APPLY) 

init_admiral: init_etcd init_iam admiral_key
	cp -rf $(RESOURCES)/terraforms/admiral.tf $(RESOURCES)/terraforms/vpc-subnet-admiral.tf $(BUILD)

# Call this explicitly to re-load user_data
update_admiral_user_data:
	cd $(BUILD); \
		${TF_TAINT} aws_s3_bucket_object.admiral_cloud_config ; \
		$(TF_APPLY)

get_admiral_ips:
	@echo "admiral public ips: " `$(SCRIPTS)/get-ec2-public-id.sh admiral`

.PHONY: admiral plan_destroy_admiral destroy_admiral plan_admiral init_admiral get_admiral_ips update_admiral_user_data
.PHONY: create_admiral_key destroy_admiral_key  upload_admiral_key clean_admiral
