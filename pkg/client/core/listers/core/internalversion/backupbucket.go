/*
Copyright (c) SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Code generated by lister-gen. DO NOT EDIT.

package internalversion

import (
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/client-go/tools/cache"

	core "github.com/gardener/gardener/pkg/apis/core"
)

// BackupBucketLister helps list BackupBuckets.
// All objects returned here must be treated as read-only.
type BackupBucketLister interface {
	// List lists all BackupBuckets in the indexer.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*core.BackupBucket, err error)
	// Get retrieves the BackupBucket from the index for a given name.
	// Objects returned here must be treated as read-only.
	Get(name string) (*core.BackupBucket, error)
	BackupBucketListerExpansion
}

// backupBucketLister implements the BackupBucketLister interface.
type backupBucketLister struct {
	indexer cache.Indexer
}

// NewBackupBucketLister returns a new BackupBucketLister.
func NewBackupBucketLister(indexer cache.Indexer) BackupBucketLister {
	return &backupBucketLister{indexer: indexer}
}

// List lists all BackupBuckets in the indexer.
func (s *backupBucketLister) List(selector labels.Selector) (ret []*core.BackupBucket, err error) {
	err = cache.ListAll(s.indexer, selector, func(m interface{}) {
		ret = append(ret, m.(*core.BackupBucket))
	})
	return ret, err
}

// Get retrieves the BackupBucket from the index for a given name.
func (s *backupBucketLister) Get(name string) (*core.BackupBucket, error) {
	obj, exists, err := s.indexer.GetByKey(name)
	if err != nil {
		return nil, err
	}
	if !exists {
		return nil, errors.NewNotFound(core.Resource("backupbucket"), name)
	}
	return obj.(*core.BackupBucket), nil
}
