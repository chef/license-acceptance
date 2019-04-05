package main

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	toml "github.com/BurntSushi/toml"
)

// Product - Data object representing a Chef Software product
type Product struct {
	Name       string
	PrettyName string `toml:"pretty_name"`
	HabPkgID   string `toml:"hab_pkg_id"`
	Filename   string
}

// ProductSet - A simple list of products, meant to hold unique entries
type ProductSet []Product

// Relationships - a mapping from a product name to a list of 'contained'/'children'
// products. EG, Chef Client contains InSpec.
type Relationships map[string]([]string)

// ProductInfo - Data object which contains the set of all known products, all
// known relationships and some maps for quick product lookup by keys.
type ProductInfo struct {
	Products       ProductSet
	Relationships  Relationships
	ProductByHabID map[string]Product
	ProductByName  map[string]Product
}

// ReadProductInfo - Load product info from disk or fail if it cannot be read.
func ReadProductInfo() *ProductInfo {
	// This env var should be set when running in production
	location, set := os.LookupEnv("CHEF_LICENSE_PRODUCT_INFO")
	if set == false {
		location = "../../product_info.toml"
	}

	var info ProductInfo
	if _, err := toml.DecodeFile(location, &info); err != nil {
		fmt.Println("Could not read product information")
		os.Exit(172)
	}
	info.ProductByHabID = make(map[string]Product, 0)
	info.ProductByName = make(map[string]Product, 0)
	for _, product := range info.Products {
		if product.HabPkgID == "" {
			continue
		}
		info.ProductByHabID[product.HabPkgID] = product
		info.ProductByName[product.Name] = product
	}
	return &info
}

// RequiredProductLicenses - For a given habitat package id look up the list of
// licenses that must be accepted (habitat package and any children). Does not check
// if licenses exist on disk. Fail if the specified habitat package or its children
// were not defined in the product info.
func (info *ProductInfo) RequiredProductLicenses(habPkgID string) []Product {
	required := make([]Product, 0)
	firstProduct, ok := info.ProductByHabID[habPkgID]
	if !ok {
		fmt.Printf("Missing product with Hab ID %s in product_info.toml\n", habPkgID)
		os.Exit(172)
	}
	required = append(required, firstProduct)
	childrenNames, ok := info.Relationships[firstProduct.Name]
	if ok {
		for _, childName := range childrenNames {
			child, ok := info.ProductByName[childName]
			if !ok {
				fmt.Printf("Defined relationship from %s to %s in product_info.toml but child does not exist\n", firstProduct.Name, childName)
				os.Exit(172)
			}
			required = append(required, child)
		}
	}
	return required
}

// HasAcceptedLicense - Return true if the given product already has a license
// persisted to disk.
func HasAcceptedLicense(config Configuration, product Product) bool {
	searchPaths := config.ReadPaths
	for _, path := range searchPaths {
		if _, err := os.Stat(filepath.Join(path, product.Filename)); err == nil {
			return true
		}
	}
	return false
}

// AttemptPersistLicense - Attempt to persist the license marker file for the
// given product. Does not fail if the file cannot be written. Returns the number
// of licenses persisted (1 or 0) and any error.
func AttemptPersistLicense(config Configuration, product Product, t time.Time, acceptingProductName string, acceptingProductVersion string, username string) (int, error) {
	err := os.MkdirAll(config.PersistPath, 0755)
	if err != nil {
		return 0, err
	}

	path := filepath.Join(config.PersistPath, product.Filename)
	f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0644)
	if err != nil {
		// We do not return the err here because its likely caused by the license
		// already existing. Golang says not to do a stat because the file could
		// be written between doing a stat and trying to write to it. They recommend
		// simply trying to write to it and dealing with the O_EXCL error if it
		// already exists.
		if err.(*os.PathError).Err.Error() == "file exists" {
			return 0, nil
		}
		return 0, err
	}

	formattedTime := t.Format(time.RFC3339)
	out := "---\n" +
		"name: %s\n" +
		"date_accepted: '%s'\n" +
		"accepting_product: %s\n" +
		"accepting_product_version: %s\n" +
		"user: %s\n" +
		"file_format: 1"
	out = fmt.Sprintf(out, product.Name, formattedTime, acceptingProductName, acceptingProductVersion, username)

	_, err = f.Write([]byte(out))
	if err != nil {
		return 0, err
	}
	if err = f.Close(); err != nil {
		return 1, err
	}
	return 1, nil
}
