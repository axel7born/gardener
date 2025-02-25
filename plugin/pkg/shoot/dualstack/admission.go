// SPDX-FileCopyrightText: 2025 SAP SE or an SAP affiliate company and Gardener contributors
//
// SPDX-License-Identifier: Apache-2.0

package dualstack

import (
	"context"
	"errors"
	"io"

	apierrors "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apiserver/pkg/admission"

	"github.com/gardener/gardener/pkg/apis/core"
	gardencorehelper "github.com/gardener/gardener/pkg/apis/core/helper"
	v1beta1constants "github.com/gardener/gardener/pkg/apis/core/v1beta1/constants"
	"github.com/gardener/gardener/pkg/controllerutils"
	plugin "github.com/gardener/gardener/plugin/pkg"
)

// Register registers a plugin.
func Register(plugins *admission.Plugins) {
	plugins.Register(plugin.PluginNameShootDualstackMigration, func(_ io.Reader) (admission.Interface, error) {
		return New(), nil
	})
}

// ShootDualstackMigration contains required information to process admission requests.
type ShootDualstackMigration struct {
	*admission.Handler
}

// New creates a new ShootDualstackMigration admission plugin.
func New() admission.MutationInterface {
	return &ShootDualstackMigration{
		Handler: admission.NewHandler(admission.Update),
	}
}

// Admit defaults spec.systemComponents.nodeLocalDNS.enabled=true for new shoot clusters.
func (c *ShootDualstackMigration) Admit(_ context.Context, a admission.Attributes, _ admission.ObjectInterfaces) error {
	switch {
	case a.GetKind().GroupKind() != core.Kind("Shoot"),
		a.GetOperation() != admission.Update,
		a.GetSubresource() != "":
		return nil
	}

	shoot, ok := a.GetObject().(*core.Shoot)
	if !ok {
		return apierrors.NewInternalError(errors.New("could not convert resource into Shoot object"))
	}

	oldShoot, ok := a.GetOldObject().(*core.Shoot)
	if !ok {
		return apierrors.NewInternalError(errors.New("could not convert resource into Shoot object"))
	}

	if !gardencorehelper.IsWorkerless(shoot) {
		if len(oldShoot.Spec.Networking.IPFamilies) < len(shoot.Spec.Networking.IPFamilies) &&
			oldShoot.Spec.Networking.IPFamilies[0] == core.IPFamilyIPv4 &&
			shoot.Spec.Networking.IPFamilies[0] == core.IPFamilyIPv4 &&
			shoot.Spec.Networking.IPFamilies[1] == core.IPFamilyIPv6 {
			if shoot.ObjectMeta.Annotations == nil {
				shoot.ObjectMeta.Annotations = make(map[string]string)
			}
			controllerutils.AddTasks(shoot.ObjectMeta.Annotations, v1beta1constants.ShootTaskDeployInfrastructure)
		}
	}
	return nil
}
