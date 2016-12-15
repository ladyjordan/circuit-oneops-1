name "containerized"
description "Containerized Application"
type "Platform"
category "Other"

environment "single", {}
environment "redundant", {}

entrypoint "fqdn"

platform :attributes => {
                "replace_after_minutes" => 60,
                "replace_after_repairs" => 3
        }


resource "image",
  :cookbook => "oneops.1.image",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "*registry" },
  :attributes => {
    :image_type => 'registry',
    :image => 'nginx'
  }

resource "storage",
  :cookbook => "oneops.1.storage",
  :design => true,
  :attributes => {
    "size"        => '20G',
    "slice_count" => '1'
  },
  :requires => { "constraint" => "0..*", "services" => "storage" }

resource "realm",
  :cookbook => "oneops.1.realm",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "container" },
  :attributes => {}

resource "container",
  :cookbook => "oneops.1.container",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "container" },
  :attributes => {
    :image_type => 'registry',
    :image => 'nginx',
    :ports => '{"http":"80"}'
  }

resource "set",
  :cookbook => "oneops.1.set",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "container" },
  :attributes => {
    :replicas => '3',
    :parallelism => '1'
  }

resource "lb",
  :except => [ 'single' ],
  :design => true,
  :cookbook => "oneops.1.lb",
  :requires => { "constraint" => "1..1", "services" => "lb,dns" },
  :attributes => {
  },
  :payloads => {
    'primaryactiveclouds' => {
      'description' => 'primaryactiveclouds',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.Lb",
         "relations": [
           { "returnObject": false,
             "returnRelation": false,
             "relationName": "manifest.Requires",
             "direction": "to",
             "targetClassName": "manifest.Platform",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"},
                                  {"attributeName":"adminstatus", "condition":"neq", "avalue":"offline"}],
                 "relationName": "base.Consumes",
                 "direction": "from",
                 "targetClassName": "account.Cloud",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"lb"}],
                     "relationName": "base.Provides",
                     "direction": "from",
                     "targetClassName": "cloud.service.Netscaler"
                   }
                 ]
               }
             ]
           }
         ]
      }'
    }
  }

resource "fqdn",
  :cookbook => "oneops.1.fqdn",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "dns,*gdns" },
  :attributes => { "aliases" => '[]' },
  :payloads => {
'environment' => {
    'description' => 'Environment',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Fqdn",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": true,
               "returnRelation": false,
               "relationName": "manifest.ComposedOf",
               "direction": "to",
               "targetClassName": "manifest.Environment"
             }
           ]
         }
       ]
    }'
  },
'activeclouds' => {
    'description' => 'activeclouds',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Fqdn",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"},
                                {"attributeName":"adminstatus", "condition":"eq", "avalue":"active"}],
               "relationName": "base.Consumes",
               "direction": "from",
               "targetClassName": "account.Cloud",
               "relations": [
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "relationName": "base.Provides",
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Netscaler"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "direction": "from",
                   "targetClassName": "cloud.service.Netscaler"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Route53"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Designate"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Rackspacedns"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "relationName": "base.Provides",
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Azuretrafficmanager"
                 }
               ]
             }
           ]
         }
       ]
    }'
  },
'organization' => {
    'description' => 'Organization',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Fqdn",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.ComposedOf",
               "direction": "to",
               "targetClassName": "manifest.Environment",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.RealizedIn",
                   "direction": "to",
                   "targetClassName": "account.Assembly",
                   "relations": [
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Manages",
                       "direction": "to",
                       "targetClassName": "account.Organization"
                     }
                   ]
                 }
               ]
             }
           ]
         }
       ]
    }'
  },
 'lb' => {
    'description' => 'all loadbalancers',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "bom.DependsOn",
       "direction": "from",
       "targetClassName": "bom.oneops.1.Lb",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "base.RealizedAs",
           "direction": "to",
           "targetClassName": "manifest.oneops.1.Lb",
           "relations": [
             { "returnObject": true,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "from",
               "targetClassName": "bom.oneops.1.Lb"
             }
           ]
         }
       ]
    }'
  },
   'remotedns' => {
       'description' => 'Other clouds dns services',
       'definition' => '{
           "returnObject": false,
           "returnRelation": false,
           "relationName": "base.RealizedAs",
           "direction": "to",
           "targetClassName": "manifest.oneops.1.Fqdn",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.Requires",
               "direction": "to",
               "targetClassName": "manifest.Platform",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.Consumes",
                   "direction": "from",
                   "targetClassName": "account.Cloud",
                   "relations": [
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.Infoblox"
                     },
                   { "returnObject": true,
                      "returnRelation": false,
                      "relationName": "base.Provides",
                      "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                      "direction": "from",
                      "targetClassName": "cloud.service.oneops.1.Route53"
                    },
                   { "returnObject": true,
                      "returnRelation": false,
                      "relationName": "base.Provides",
                      "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                      "direction": "from",
                      "targetClassName": "cloud.service.oneops.1.Designate"
                    },
                   { "returnObject": true,
                      "returnRelation": false,
                      "relationName": "base.Provides",
                      "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                      "direction": "from",
                      "targetClassName": "cloud.service.oneops.1.Rackspacedns"
                    },
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.oneops.1.Infoblox"
                     }
                   ]
                 }
               ]
             }
           ]
      }'
    },
   'remotegdns' => {
       'description' => 'Other clouds gdns services',
       'definition' => '{
           "returnObject": false,
           "returnRelation": false,
           "relationName": "base.RealizedAs",
           "direction": "to",
           "targetClassName": "manifest.oneops.1.Fqdn",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.Requires",
               "direction": "to",
               "targetClassName": "manifest.Platform",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.Consumes",
                   "direction": "from",
                   "targetClassName": "account.Cloud",
                   "relations": [
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.oneops.1.Netscaler"
                     },
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.Netscaler"
                     },
                     { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.Provides",
                        "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                        "direction": "from",
                        "targetClassName": "cloud.service.oneops.1.Route53"
                      },
                     { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.Provides",
                        "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                        "direction": "from",
                        "targetClassName": "cloud.service.oneops.1.Designate"
                      },
                     { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.Provides",
                        "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                        "direction": "from",
                        "targetClassName": "cloud.service.oneops.1.Rackspacedns"
                      },
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.oneops.1.Azuretrafficmanager"
                     }
                   ]
                 }
               ]
             }
           ]
      }'
    }
  }


# depends_on

#single
[ 'fqdn' ].each do |from|
  relation "#{from}::depends_on::container",
    :only => [ 'single' ],
    :design => false,
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'container',
    :attributes    => { "propagate_to" => 'from' }
end

#redundant
[ 'fqdn' ].each do |from|
  relation "#{from}::depends_on::lb",
    :except => [ 'single' ],
    :design => true,
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'lb',
    :attributes    => { "propagate_to" => 'from' }
end

[ 'lb' ].each do |from|
  relation "#{from}::depends_on::container",
    :except => [ 'single' ],
    :design => true,
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'container',
    :attributes    => { "propagate_to" => 'from', "flex" => true, "current" =>3, "min" => 3, "max" => 10 }
end

[ { :from => 'set',  :to => 'container' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    # :only => [ 'fungible' ],
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { }
end

[ { :from => 'container',  :to => 'image' },
  { :from => 'container',  :to => 'storage' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "propagate_to" => 'from' }
end

[ { :from => 'container',  :to => 'realm' },
  { :from => 'storage',  :to => 'realm' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { }
end
